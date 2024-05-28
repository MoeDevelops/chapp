import gleam/json.{type Json}
import youid/uuid.{type Uuid}

// - User -

pub type User {
  User(id: Uuid, username: String, created_at: Int)
}

pub fn user_to_json(user: User) -> Json {
  json.object([
    #("id", json.string(user.id |> uuid.to_string())),
    #("username", json.string(user.username)),
    #("created_at", json.int(user.created_at)),
  ])
}

// - Message -

pub type Message {
  Message(
    id: Uuid,
    user_id: String,
    chat_id: String,
    content: String,
    created_at: Int,
  )
}

pub fn message_to_json(message: Message) -> Json {
  json.object([
    #("id", json.string(message.id |> uuid.to_string())),
    #("user_id", json.string(message.user_id)),
    #("chat_id", json.string(message.chat_id)),
    #("content", json.string(message.content)),
    #("created_at", json.int(message.created_at)),
  ])
}

// - Chat -

pub type Chat {
  Chat(id: Uuid, name: String, created_at: Int)
}

pub fn chat_to_json(chat: Chat) -> Json {
  json.object([
    #("id", json.string(chat.id |> uuid.to_string())),
    #("name", json.string(chat.name)),
    #("created_at", json.int(chat.created_at)),
  ])
}
