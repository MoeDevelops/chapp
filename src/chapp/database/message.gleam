import chapp/database
import chapp/models.{type Message, Message}
import gleam/dynamic
import gleam/pgo.{type Connection as DbConnection}
import youid/uuid.{type Uuid}

const create_message_sql = "
insert into
messages (id, user_id, chat_id, content, created_at)
values ($1, $2, $3, $4, $5)"

pub fn create_message(
  connection: DbConnection,
  user_id: Uuid,
  chat_id: Uuid,
  content: String,
) -> Result(Message, Nil) {
  let id = uuid.v4()
  let created_at = database.get_timestamp()

  use _ <- database.try_log_error(
    pgo.execute(
      create_message_sql,
      connection,
      [
        pgo.bytea(uuid.to_bit_array(id)),
        pgo.bytea(uuid.to_bit_array(user_id)),
        pgo.bytea(uuid.to_bit_array(chat_id)),
        pgo.text(content),
        pgo.int(created_at),
      ],
      dynamic.dynamic,
    ),
    Nil,
  )

  Ok(Message(id, user_id, chat_id, content, created_at))
}

const get_message_by_id_sql = "
select user_id, chat_id, content, created_at
from messages
where id = $1
limit 1;
"

pub fn get_message_by_id(
  connection: DbConnection,
  id: Uuid,
) -> Result(Message, Nil) {
  use db_result <- database.try_log_error(
    pgo.execute(
      get_message_by_id_sql,
      connection,
      [pgo.bytea(uuid.to_bit_array(id))],
      dynamic.tuple4(
        dynamic.field("user_id", dynamic.bit_array),
        dynamic.field("chat_id", dynamic.bit_array),
        dynamic.field("content", dynamic.string),
        dynamic.field("created_at", dynamic.int),
      ),
    ),
    Nil,
  )

  case db_result.rows {
    [#(user_id, chat_id, content, created_at), ..] ->
      Ok(Message(
        id,
        {
          let assert Ok(user_id) = uuid.from_bit_array(user_id)
          user_id
        },
        {
          let assert Ok(chat_id) = uuid.from_bit_array(chat_id)
          chat_id
        },
        content,
        created_at,
      ))
    _ -> Error(Nil)
  }
}
