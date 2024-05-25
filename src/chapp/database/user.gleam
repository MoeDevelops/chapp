import chapp/database
import chapp/database/token
import chapp/models.{type TokenPair, type User, TokenPair, User}
import gleam/bit_array
import gleam/crypto.{Sha512}
import gleam/dynamic

import gleam/list
import gleam/pgo.{type Connection as DbConnection}
import gleam/result
import gleam/string
import youid/uuid

pub fn create_user(
  connection: DbConnection,
  username: String,
  password: String,
) -> Result(TokenPair, Nil) {
  let salt = crypto.strong_random_bytes(64)
  let password_bin = bit_array.from_string(password)
  let pw_hashed = hash_password(password_bin, salt)

  let id =
    uuid.v4()
    |> uuid.to_string()

  let db_result =
    create_user_sql
    |> pgo.execute(
      connection,
      [
        pgo.bytea({
          let assert Ok(bits) =
            id
            |> string.replace("-", "")
            |> bit_array.base16_decode()
          bits
        }),
        pgo.text(username),
        pgo.bytea(pw_hashed),
        pgo.bytea(salt),
        pgo.int(database.get_timestamp()),
      ],
      dynamic.dynamic,
    )

  case db_result {
    Ok(_) -> token.create_token_pair(connection, id)
    Error(err) -> database.log_error(err)
  }
}

pub fn login(
  connection: DbConnection,
  username: String,
  password: String,
) -> Result(TokenPair, Nil) {
  use user <- result.try(get_user_by_username(connection, username))
  use salt <- result.try(get_salt(connection, user.id))
  let password_bin = bit_array.from_string(password)
  let hashed_pw = hash_password(password_bin, salt)

  case
    login_sql
    |> pgo.execute(
      connection,
      [pgo.text(username), pgo.bytea(hashed_pw), pgo.bytea(salt)],
      dynamic.element(0, dynamic.bit_array),
    )
  {
    Ok(db_result) ->
      case db_result.rows |> list.first() {
        Ok(id) -> {
          connection
          |> token.create_token_pair(id |> bit_array.base16_encode())
        }
        Error(_) -> Error(Nil)
      }
    Error(err) -> database.log_error(err)
  }
}

fn get_salt(connection: DbConnection, id: String) -> Result(BitArray, Nil) {
  case
    get_salt_sql
    |> pgo.execute(
      connection,
      [pgo.text(id)],
      dynamic.element(0, dynamic.bit_array),
    )
  {
    Ok(db_result) ->
      db_result.rows
      |> list.first

    Error(err) -> database.log_error(err)
  }
}

pub fn delete_user(connection: DbConnection, id: String) -> Result(Nil, String) {
  case
    delete_user_sql
    |> pgo.execute(connection, [pgo.text(id)], dynamic.dynamic)
  {
    Ok(_) -> Ok(Nil)
    Error(err) -> {
      let _ = database.log_error(err)
      Error("Error during database execution")
    }
  }
}

pub fn get_user_by_username(
  connection: DbConnection,
  username: String,
) -> Result(User, Nil) {
  case
    get_user_by_username_sql
    |> pgo.execute(
      connection,
      [pgo.text(username)],
      dynamic.tuple3(dynamic.bit_array, dynamic.string, dynamic.int),
    )
  {
    Ok(db_result) -> {
      case
        db_result.rows
        |> list.first()
      {
        Ok(#(id, username, created_at)) ->
          Ok(User(id |> bit_array.base16_encode(), username, created_at))
        _ -> Error(Nil)
      }
    }
    Error(err) -> database.log_error(err)
  }
}

fn hash_password(password: BitArray, salt: BitArray) -> BitArray {
  let pw_and_salt = bit_array.append(password, salt)

  crypto.hash(Sha512, pw_and_salt)
}

const login_sql = "
select id
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
where id = $1
limit 1;
"

const get_user_by_username_sql = "
select id, username, created_at
from users
where username = $1
limit 1;
"

const delete_user_sql = "
delete
from users
where id = $1;
"
