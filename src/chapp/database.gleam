import birl
import gleam/bit_array
import gleam/crypto.{Sha512}
import gleam/dynamic
import gleam/option.{type Option, None, Some}
import gleam/pgo.{type Connection as DbConnection}
import gleam/result
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

pub type TokenPair {
  TokenPair(user: String, token: String)
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

pub fn create_tables(connection: DbConnection) -> Bool {
  create_tables_sql
  |> pgo.execute(connection, [], dynamic.dynamic)
  |> result.is_ok()
}

pub fn create_user(
  connection: DbConnection,
  username: String,
  password: String,
) -> Option(TokenPair) {
  let salt = crypto.strong_random_bytes(256)
  let pw_and_salt =
    bit_array.from_string(password)
    |> bit_array.append(salt)

  let pw_hashed = crypto.hash(Sha512, pw_and_salt)
  let db_result =
    create_user_sql
    |> pgo.execute(
      connection,
      [
        pgo.text(username),
        pgo.text(bit_array.base16_encode(pw_hashed)),
        pgo.text(bit_array.base16_encode(salt)),
        pgo.int(get_timestamp()),
      ],
      dynamic.dynamic,
    )

  case db_result {
    Ok(_) -> Some(create_token_pair(connection, username))
    Error(_) -> None
  }
}

fn create_token_pair(connection: DbConnection, username: String) -> TokenPair {
  let token = uuid.v4_string()
  let _ =
    create_token_sql
    |> pgo.execute(
      connection,
      [pgo.text(token), pgo.text(username), pgo.int(get_timestamp())],
      dynamic.dynamic,
    )
  TokenPair(username, token)
}

fn verify_token(connection: DbConnection, token_pair: TokenPair) {
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

pub fn get_user(connection: DbConnection, username: String) -> Option(String) {
  todo
}

pub fn create_message(
  connection: DbConnection,
  token: String,
  recipient: String,
  content: String,
) -> Option(Message) {
  let db_result =
    create_message_sql
    |> pgo.execute(connection, [], dynamic.dynamic)
  todo
}

pub fn get_messages(
  connection: DbConnection,
  token: String,
  user: String,
) -> Option(List(Message)) {
  todo
}

fn get_timestamp() -> Int {
  birl.utc_now()
  |> birl.to_unix()
}

const create_tables_sql = "
create table if not exists Users 
(username varchar(32) primary key, salt char(64), creation_timestamp bigint);

create table if not exists Messages
(id uuid primary key, 
author varchar(32) references Users(username),
recipient varchar(32) references Users(username), 
message_content varchar(1000), creation_timestamp bigint);

create table if not exists tokens(
token uuid primary key,
username varchar(32) references users(username),
creation_timestamp bigint
);

create index if not exists idx_messages_author on Messages(author);
create index if not exists idx_messages_recipient on Messages(recipient);
create index if not exists idx_tokens_token on tokens(token);
"

const create_user_sql = "
insert into 
users (username, password, salt, creation_timestamp) 
values ($1, $2, $3, $4);
"

const create_token_sql = "
insert into
tokens (token, username, creation_timestamp)
values ($1, $2, $3)
"

const create_message_sql = "
insert into
messages (id, author, recipient, message_content, creation_timestamp)
values ($1, $2, $3, $4, $5)"
