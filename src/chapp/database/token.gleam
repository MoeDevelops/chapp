import chapp/database
import chapp/models.{type User, User}
import gleam/dynamic
import gleam/list
import gleam/pgo.{type Connection as DbConnection}
import youid/uuid.{type Uuid}

const create_token_sql = "
insert into
tokens (token, user_id, created_at)
values ($1, $2, $3);
"

pub fn create_token(
  connection: DbConnection,
  user_id: Uuid,
) -> Result(Uuid, Nil) {
  let token = uuid.v4()
  let created_at = database.get_timestamp()

  use _ <- database.try_log_error(
    pgo.execute(
      create_token_sql,
      connection,
      [
        pgo.bytea(uuid.to_bit_array(token)),
        pgo.bytea(uuid.to_bit_array(user_id)),
        pgo.int(created_at),
      ],
      dynamic.dynamic,
    ),
    Nil,
  )

  Ok(token)
}

const verify_token_sql = "
select 1
from tokens
where user_id = $1 and token = $2;
"

pub fn verify_token(
  connection: DbConnection,
  user_id: Uuid,
  token: Uuid,
) -> Result(Nil, Nil) {
  use db_result <- database.try_log_error(
    pgo.execute(
      verify_token_sql,
      connection,
      [
        pgo.bytea(uuid.to_bit_array(user_id)),
        pgo.bytea(uuid.to_bit_array(token)),
      ],
      dynamic.dynamic,
    ),
    Nil,
  )

  case db_result.rows |> list.is_empty {
    True -> Error(Nil)
    False -> Ok(Nil)
  }
}

const get_user_by_token_sql = "
select u.id, u.username, u.created_at
from tokens t
inner join users u on t.user_id = u.id
where t.token = $1
limit 1;
"

pub fn get_user_by_token(
  connection: DbConnection,
  token: Uuid,
) -> Result(User, Nil) {
  use db_result <- database.try_log_error(
    pgo.execute(
      get_user_by_token_sql,
      connection,
      [pgo.bytea(uuid.to_bit_array(token))],
      dynamic.tuple3(dynamic.bit_array, dynamic.string, dynamic.int),
    ),
    Nil,
  )

  case db_result.rows |> list.first() {
    Ok(#(id, username, created_at)) ->
      Ok(User(
        {
          let assert Ok(uuid) = uuid.from_bit_array(id)
          uuid
        },
        username,
        created_at,
      ))
    _ -> Error(Nil)
  }
}
