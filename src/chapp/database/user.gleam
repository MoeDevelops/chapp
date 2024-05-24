import chapp/database
import chapp/database/token
import chapp/models.{type TokenPair, type User, TokenPair, User}
import gleam/bit_array
import gleam/crypto.{Sha512}
import gleam/dynamic
import gleam/list
import gleam/pgo.{type Connection as DbConnection}
import gleam/result
import youid/uuid

pub fn create_user(
  connection: DbConnection,
  username: String,
  password: String,
) -> Result(TokenPair, Nil) {
  let salt = crypto.strong_random_bytes(64)
  let password_bin = bit_array.from_string(password)

  let pw_hashed = hash_password(password_bin, salt)

  let id = uuid.v4_string()

  let db_result =
    create_user_sql
    |> pgo.execute(
      connection,
      [
        pgo.text(id),
        pgo.text(username),
        pgo.bytea(pw_hashed),
        pgo.bytea(salt),
        pgo.int(database.get_timestamp()),
      ],
      dynamic.dynamic,
    )

  case db_result {
    Ok(_) -> Ok(token.create_token_pair(connection, username))
    Error(err) -> database.log_error(err)
  }
}

fn hash_password(password: BitArray, salt: BitArray) -> BitArray {
  let pw_and_salt = bit_array.append(password, salt)

  crypto.hash(Sha512, pw_and_salt)
}

pub fn login(
  connection: DbConnection,
  username: String,
  password: String,
) -> Result(TokenPair, Nil) {
  use salt <- result.try(get_salt(connection, username))
  let password_bin = bit_array.from_string(password)

  let hashed_pw = hash_password(password_bin, salt)

  case
    login_sql
    |> pgo.execute(
      connection,
      [pgo.text(username), pgo.bytea(hashed_pw), pgo.bytea(salt)],
      dynamic.element(0, dynamic.string),
    )
  {
    Ok(db_result) ->
      case db_result.count != 0 {
        True ->
          Ok(
            connection
            |> token.create_token_pair(username),
          )
        False -> Error(Nil)
      }
    Error(err) -> database.log_error(err)
  }
}

fn get_salt(connection: DbConnection, username: String) -> Result(BitArray, Nil) {
  case
    get_salt_sql
    |> pgo.execute(
      connection,
      [pgo.text(username)],
      dynamic.element(0, dynamic.bit_array),
    )
  {
    Ok(db_result) ->
      db_result.rows
      |> list.first

    Error(err) -> database.log_error(err)
  }
}

pub fn delete_user(
  connection: DbConnection,
  token: String,
) -> Result(Nil, String) {
  let user = token.get_user_by_token(connection, token)

  case user {
    Ok(user) -> {
      case
        delete_user_sql
        |> pgo.execute(connection, [pgo.text(user.username)], dynamic.dynamic)
      {
        Ok(_) -> Ok(Nil)
        Error(err) -> {
          let _ = database.log_error(err)
          Error("Error during database execution")
        }
      }
    }
    Error(_) -> Error("No user matching the token found")
  }
}

pub fn get_user(connection: DbConnection, username: String) -> Result(User, Nil) {
  case
    get_user_sql
    |> pgo.execute(
      connection,
      [pgo.text(username)],
      dynamic.tuple3(dynamic.string, dynamic.string, dynamic.int),
    )
  {
    Ok(db_result) -> {
      case
        db_result.rows
        |> list.first()
      {
        Ok(row) ->
          case row {
            #(id, username, created_at) -> Ok(User(id, username, created_at))
          }
        _ -> Error(Nil)
      }
    }
    Error(err) -> database.log_error(err)
  }
}

const login_sql = "
select username
from users
where username = $1 and password = $2 and salt = $3
"

const create_user_sql = "
insert into 
users (id, username, password, salt, created_at) 
values ($1, $2, $3, $4, $5);
"

const get_salt_sql = "
select salt
from users
where username = $1
limit 1;
"

const get_user_sql = "
select username, created_at
from users
where username = $1
limit 1;
"

const delete_user_sql = "
delete
from users
where username = $1;
"
