import chapp/database
import chapp/database/token.{type TokenPair}
import gleam/bit_array
import gleam/crypto.{Sha512}
import gleam/dynamic
import gleam/option.{type Option, None, Some}
import gleam/pgo.{type Connection as DbConnection}

pub fn create_user(
  connection: DbConnection,
  username: String,
  password: String,
) -> Option(TokenPair) {
  let salt = crypto.strong_random_bytes(256)
  let pw_and_salt =
    bit_array.from_string(password)
    |> bit_array.append(salt)

  let pw_hashed = crypto.hash(Sha512, pw_and_salt)
  let db_result =
    create_user_sql
    |> pgo.execute(
      connection,
      [
        pgo.text(username),
        pgo.text(bit_array.base16_encode(pw_hashed)),
        pgo.text(bit_array.base16_encode(salt)),
        pgo.int(database.get_timestamp()),
      ],
      dynamic.dynamic,
    )

  case db_result {
    Ok(_) -> Some(token.create_token_pair(connection, username))
    Error(_) -> None
  }
}

pub fn login(
  connection: DbConnection,
  username: String,
  password: String,
) -> Option(TokenPair) {
  todo
}

pub fn delete_user(connect: DbConnection, token: String) -> Result(Nil, String) {
  todo
}

pub fn get_user(connection: DbConnection, username: String) -> Option(String) {
  todo
}

const create_user_sql = "
insert into 
users (username, password, salt, creation_timestamp) 
values ($1, $2, $3, $4);
"
