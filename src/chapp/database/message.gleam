import chapp/database
import chapp/database/token
import gleam/dynamic
import gleam/option.{type Option, None, Some}
import gleam/pgo.{type Connection as DbConnection}
import youid/uuid

pub type Message {
  Message(
    id: String,
    author: String,
    recipient: String,
    message_content: String,
    creation_timestamp: Int,
  )
}

pub fn create_message(
  connection: DbConnection,
  token: String,
  recipient: String,
  content: String,
) -> Option(Message) {
  let id = uuid.v4_string()
  let author =
    connection
    |> token.get_user_by_token(token)
    |> option.unwrap("")

  let timestamp = database.get_timestamp()

  let db_result =
    create_message_sql
    |> pgo.execute(connection, [], dynamic.dynamic)

  case db_result {
    Ok(_) -> Some(Message(id, author, recipient, content, timestamp))
    Error(_) -> None
  }
}

pub fn get_messages(
  connection: DbConnection,
  token: String,
  user: String,
) -> Option(List(Message)) {
  todo
}

const create_message_sql = "
insert into
messages (id, author, recipient, message_content, creation_timestamp)
values ($1, $2, $3, $4, $5)"

const get_messages_sql = "

"
