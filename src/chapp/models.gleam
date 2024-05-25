import gleam/json.{type Json}

// - TokenPair -

pub type TokenPair {
  TokenPair(user_id: String, token: String)
}

// - User -

pub type User {
  User(id: String, username: String, created_at: Int)
}

pub fn user_to_json(user: User) -> Json {
  json.object([
    #("id", json.string(user.id)),
    #("username", json.string(user.username)),
    #("created_at", json.int(user.created_at)),
  ])
}

// - Message -

pub type Message {
  Message(
    id: String,
    user_id: String,
    chat_id: String,
    content: String,
    created_at: Int,
  )
}

pub fn message_to_json(message: Message) -> Json {
  json.object([
    #("id", json.string(message.id)),
    #("user_id", json.string(message.user_id)),
    #("chat_id", json.string(message.chat_id)),
    #("content", json.string(message.content)),
    #("created_at", json.int(message.created_at)),
  ])
}

// - Chat -

pub type Chat {
  Chat(id: String, name: String, created_at: Int)
}
