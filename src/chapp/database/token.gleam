import chapp/database
import gleam/dynamic
import gleam/option.{type Option, None, Some}
import gleam/pgo.{type Connection as DbConnection}
import youid/uuid

pub type TokenPair {
  TokenPair(username: String, token: String)
}

pub fn create_token_pair(
  connection: DbConnection,
  username: String,
) -> TokenPair {
  let token = uuid.v4_string()
  let _ =
    create_token_sql
    |> pgo.execute(
      connection,
      [pgo.text(token), pgo.text(username), pgo.int(database.get_timestamp())],
      dynamic.dynamic,
    )
  TokenPair(username, token)
}

pub fn verify_token(connection: DbConnection, token_pair: TokenPair) {
  todo
}

pub fn get_user_by_token(
  connection: DbConnection,
  token: String,
) -> Option(String) {
  todo
}

const create_token_sql = "
insert into
tokens (token, username, creation_timestamp)
values ($1, $2, $3)
"
