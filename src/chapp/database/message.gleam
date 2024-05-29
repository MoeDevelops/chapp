import chapp/database
import chapp/database/token
import chapp/models.{type Message, Message}
import gleam/dynamic
import gleam/pgo.{type Connection as DbConnection}
import gleam/result
import youid/uuid.{type Uuid}

const create_message_sql = "
insert into
messages (id, user_id, chat_id, content, created_at)
values ($1, $2, $3, $4, $5)"

pub fn create_message(
  connection: DbConnection,
  token: Uuid,
  chat_id: Uuid,
  content: String,
) -> Result(Message, Nil) {
  let id = uuid.v4()
  use author <- result.try(token.get_user_by_token(connection, token))

  let timestamp = database.get_timestamp()

  case
    create_message_sql
    |> pgo.execute(
      connection,
      [
        pgo.bytea(uuid.to_bit_array(id)),
        pgo.text(author.username),
        pgo.bytea(uuid.to_bit_array(chat_id)),
        pgo.text(content),
        pgo.int(timestamp),
      ],
      dynamic.dynamic,
    )
  {
    Ok(_) -> Ok(Message(id, author.id, chat_id, content, timestamp))
    Error(err) -> database.log_error(err)
  }
}
