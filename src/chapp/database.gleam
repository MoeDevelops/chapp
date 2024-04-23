import birl
import gleam/dynamic
import gleam/pgo.{type Connection as DbConnection}
import gleam/result

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

pub fn get_timestamp() -> Int {
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
