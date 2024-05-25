import chapp/database
import chapp/database/token
import chapp/models.{type Message, Message}
import gleam/bit_array
import gleam/dynamic
import gleam/list
import gleam/pgo.{type Connection as DbConnection}
import gleam/result
import youid/uuid

pub fn create_message(
  connection: DbConnection,
  token: String,
  chat_id: String,
  content: String,
) -> Result(Message, Nil) {
  let id = uuid.v4_string()
  use author <- result.try(token.get_user_by_token(connection, token))

  let timestamp = database.get_timestamp()

  case
    create_message_sql
    |> pgo.execute(
      connection,
      [
        pgo.text(id),
        pgo.text(author.username),
        pgo.text(chat_id),
        pgo.text(content),
        pgo.int(timestamp),
      ],
      dynamic.dynamic,
    )
  {
    Ok(_) -> Ok(Message(id, author.username, chat_id, content, timestamp))
    Error(err) -> database.log_error(err)
  }
}

pub fn get_messages(
  connection: DbConnection,
  token: String,
  user: String,
) -> Result(List(Message), Nil) {
  use requesting_user <- result.try(token.get_user_by_token(connection, token))

  case
    get_messages_sql
    |> pgo.execute(
      connection,
      [pgo.text(requesting_user.username), pgo.text(user)],
      dynamic.tuple5(
        dynamic.bit_array,
        dynamic.string,
        dynamic.string,
        dynamic.string,
        dynamic.int,
      ),
    )
  {
    Ok(db_result) ->
      db_result.rows
      |> list.map(decode_message)
      |> Ok
    Error(err) -> database.log_error(err)
  }
}

fn decode_message(args: #(BitArray, String, String, String, Int)) -> Message {
  case args {
    #(id, author, recipient, message_content, creation_timestamp) ->
      Message(
        id
          |> bit_array.base16_encode()
          |> uuid.from_string()
          |> result.unwrap(uuid.v4())
          |> uuid.to_string(),
        author,
        recipient,
        message_content,
        creation_timestamp,
      )
  }
}

const create_message_sql = "
insert into
messages (id, user_id, chat_id, content, created_at)
values ($1, $2, $3, $4, $5)"

const get_messages_sql = "
select id, user_id, chat_id, content, created_at
from messages
where chat_id = $1
order by creation_timestamp desc
limit 500;
"
