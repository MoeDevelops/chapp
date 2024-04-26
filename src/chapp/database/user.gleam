import chapp/database
import chapp/database/token.{type TokenPair}
import gleam/bit_array
import gleam/crypto.{Sha512}
import gleam/dynamic
import gleam/list
import gleam/pair
import gleam/pgo.{type Connection as DbConnection}
import gleam/result

pub type User {
  User(username: String, creation_timestamp: Int)
}

pub fn create_user(
  connection: DbConnection,
  username: String,
  password: String,
) -> Result(TokenPair, Nil) {
  let salt = crypto.strong_random_bytes(64)
  let password_bin = bit_array.from_string(password)

  let pw_hashed = hash_password(password_bin, salt)

  let db_result =
    create_user_sql
    |> pgo.execute(
      connection,
      [
        pgo.text(username),
        pgo.bytea(pw_hashed),
        pgo.bytea(salt),
        pgo.int(database.get_timestamp()),
      ],
      dynamic.dynamic,
    )

  case db_result {
    Ok(_) -> Ok(token.create_token_pair(connection, username))
    Error(err) -> {
      database.log_error(err)
      Error(Nil)
    }
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
    Error(err) -> {
      database.log_error(err)
      Error(Nil)
    }
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

    Error(err) -> {
      database.log_error(err)
      Error(Nil)
    }
  }
}

pub fn delete_user(
  connection: DbConnection,
  token: String,
) -> Result(Nil, String) {
  let user = token.get_user_by_token(connection, token)

  case user {
    Ok(username) -> {
      case
        delete_user_sql
        |> pgo.execute(connection, [pgo.text(username)], dynamic.dynamic)
      {
        Ok(_) -> Ok(Nil)
        Error(err) -> {
          database.log_error(err)
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
      dynamic.tuple2(dynamic.string, dynamic.int),
    )
  {
    Ok(db_result) -> {
      case
        db_result.rows
        |> list.first()
      {
        Ok(row) -> Ok(User(pair.first(row), pair.second(row)))
        _ -> Error(Nil)
      }
    }
    Error(err) -> {
      database.log_error(err)
      Error(Nil)
    }
  }
}

const login_sql = "
select username
from users
where username = $1 and password = $2 and salt = $3
"

const create_user_sql = "
insert into 
users (username, password, salt, creation_timestamp) 
values ($1, $2, $3, $4);
"

const get_salt_sql = "
select salt
from users
where username = $1
limit 1;
"

const get_user_sql = "
select username, creation_timestamp
from users
where username = $1
limit 1;
"

const delete_user_sql = "
delete
from users
where username = $1;
"
