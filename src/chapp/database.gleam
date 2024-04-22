import gleam/option.{type Option}
import gleam/pgo.{type Connection as DbConnection}

pub type User {
  User(username: String, timpstamp: Int)
}

pub type Message {
  Message(
    id: String,
    author: User,
    recipient: User,
    content: String,
    timpstamp: Int,
  )
}

pub type TokenPair {
  TokenPair(user: User, token: String)
}

pub fn create_connection(database: String) -> DbConnection {
  pgo.Config(
    ..pgo.default_config(),
    host: "localhost",
    database: database,
    pool_size: 15,
  )
  |> pgo.connect()
}

pub fn create_user(
  connection: DbConnection,
  username: String,
  password: String,
) -> Option(TokenPair) {
  todo
}

pub fn login(
  connection: DbConnection,
  username: String,
  password: String,
) -> Option(TokenPair) {
  todo
}

pub fn delete_user(connect: DbConnection, token: String) -> Result(Nil, String) {
  todo
}

pub fn get_user(connection: DbConnection, username: String) -> Option(User) {
  todo
}

pub fn create_message(
  connection: DbConnection,
  token: String,
  recipient: User,
  content: String,
) -> Option(Message) {
  todo
}

pub fn get_messages(
  connection: DbConnection,
  token: String,
  user: User,
) -> Option(List(Message)) {
  todo
}
