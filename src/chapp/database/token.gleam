import chapp/database
import gleam/bit_array
import gleam/bytes_builder
import gleam/dynamic
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo.{type Connection as DbConnection}
import gleam/result
import gleam/string
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

pub fn verify_token(connection: DbConnection, token_pair: TokenPair) -> Bool {
  case
    verify_token_sql
    |> pgo.execute(
      connection,
      [pgo.text(token_pair.username), pgo.text(token_pair.token)],
      dynamic.tuple2(dynamic.string, dynamic.bit_array),
    )
  {
    Ok(db_result) -> db_result.count == 1
    Error(err) -> {
      database.log_error(err)
      False
    }
  }
}

pub fn get_user_by_token(
  connection: DbConnection,
  token: String,
) -> Option(String) {
  let token_binary =
    token
    |> string.replace("-", "")
    |> string.lowercase()
    |> bit_array.base16_decode()
    |> result.unwrap(
      bytes_builder.new()
      |> bytes_builder.to_bit_array(),
    )

  case
    get_user_by_token_sql
    |> pgo.execute(
      connection,
      [pgo.bytea(token_binary)],
      dynamic.element(0, dynamic.string),
    )
  {
    Ok(db_result) ->
      case list.first(db_result.rows) {
        Ok(val) -> Some(val)
        _ -> None
      }
    Error(err) -> {
      database.log_error(err)
      None
    }
  }
}

pub fn token(token_pair: TokenPair) {
  token_pair.token
}

const create_token_sql = "
insert into
tokens (token, username, creation_timestamp)
values ($1, $2, $3);
"

const verify_token_sql = "
select username, token 
from tokens
where username = $1 and token = $2 
limit 1;
"

const get_user_by_token_sql = "
select username
from tokens
where token = $1
limit 1;
"
