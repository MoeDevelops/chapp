import chapp/database
import chapp/models.{type TokenPair, type User, TokenPair, User}
import gleam/bit_array
import gleam/dynamic
import gleam/list
import gleam/pgo.{type Connection as DbConnection}
import youid/uuid

pub fn create_token_pair(
  connection: DbConnection,
  user_id: String,
) -> Result(TokenPair, Nil) {
  let token = uuid.v4_string()

  case
    pgo.execute(
      create_token_sql,
      connection,
      [pgo.text(token), pgo.text(user_id), pgo.int(database.get_timestamp())],
      dynamic.dynamic,
    )
  {
    Ok(_) -> {
      Ok(TokenPair(user_id, token))
    }
    Error(err) -> {
      database.log_error(err)
    }
  }
}

pub fn verify_token(connection: DbConnection, token_pair: TokenPair) -> Bool {
  case
    verify_token_sql
    |> pgo.execute(
      connection,
      [pgo.text(token_pair.user_id), pgo.text(token_pair.token)],
      dynamic.element(0, dynamic.int),
    )
  {
    Ok(db_result) -> db_result.count == 1
    Error(err) -> {
      let _ = database.log_error(err)
      False
    }
  }
}

pub fn get_user_by_token(
  connection: DbConnection,
  token: String,
) -> Result(User, Nil) {
  case
    get_user_by_token_sql
    |> pgo.execute(
      connection,
      [pgo.text(token)],
      dynamic.tuple3(dynamic.bit_array, dynamic.string, dynamic.int),
    )
  {
    Ok(db_result) ->
      case list.first(db_result.rows) {
        Ok(row) ->
          case row {
            #(id, username, created_at) ->
              Ok(User(id |> bit_array.base16_encode(), username, created_at))
          }
        Error(_) -> Error(Nil)
      }
    Error(err) -> database.log_error(err)
  }
}

pub fn token(token_pair: TokenPair) {
  token_pair.token
}

pub fn user_id(token_pair: TokenPair) {
  token_pair.user_id
}

const create_token_sql = "
insert into
tokens (token, user_id, created_at)
values ($1, $2, $3);
"

const verify_token_sql = "
select 1
from tokens
where user_id = $1 and token = $2;
"

const get_user_by_token_sql = "
select u.id, u.username, u.created_at
from tokens t
inner join users u on t.user_id = u.id
where t.token = $1
limit 1;
"
