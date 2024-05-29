import chapp/database
import chapp/models.{type Chat, Chat}
import gleam/dynamic
import gleam/list
import gleam/pgo.{type Connection as DbConnection}
import gleam/result
import youid/uuid.{type Uuid}

const create_chat_sql = "
insert into
chats (id, name, created_at)
values ($1, $2, $3);
"

pub fn create_chat(connection: DbConnection, name: String) -> Result(Chat, Nil) {
  let id = uuid.v4()
  let created_at = database.get_timestamp()

  use _ <- database.try_log_error(
    pgo.execute(
      create_chat_sql,
      connection,
      [pgo.bytea(uuid.to_bit_array(id)), pgo.text(name), pgo.int(created_at)],
      dynamic.dynamic,
    ),
    Nil,
  )

  Ok(Chat(id, name, created_at))
}

const get_chat_by_id_sql = "
select id, name, created_at
from chats
where id = $1
limit 1;
"

pub fn get_chat_by_id(connection: DbConnection, id: Uuid) -> Result(Chat, Nil) {
  use db_result <- database.try_log_error(
    pgo.execute(
      get_chat_by_id_sql,
      connection,
      [pgo.bytea(uuid.to_bit_array(id))],
      dynamic.tuple3(dynamic.bit_array, dynamic.string, dynamic.int),
    ),
    Nil,
  )

  use #(id, name, created_at) <- result.try(db_result.rows |> list.first())
  Ok(Chat(
    {
      let assert Ok(id) = uuid.from_bit_array(id)
      id
    },
    name,
    created_at,
  ))
}
