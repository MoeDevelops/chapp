import gleam/option.{type Option}

pub type User {
  User(username: String, timpstamp: Int)
}

pub type Message {
  Message(author: User, recipient: User, content: String, timpstamp: Int)
}

pub fn create_user(
  username: String,
  password: String,
) -> Option(#(User, String)) {
  todo
}

pub fn get_user(username: String) -> Option(User) {
  todo
}

pub fn create_message(
  token: String,
  recipient: User,
  content: String,
) -> Option(Message) {
  todo
}

pub fn get_messages(token: String, user: User) -> Option(List(Message)) {
  todo
}
