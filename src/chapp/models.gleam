pub type TokenPair {
  TokenPair(username: String, token: String)
}

pub type Message {
  Message(
    id: String,
    author: String,
    recipient: String,
    message_content: String,
    creation_timestamp: Int,
  )
}

pub type User {
  User(username: String, creation_timestamp: Int)
}
