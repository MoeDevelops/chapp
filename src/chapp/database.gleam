import birl
import chapp/config
import gleam/bit_array
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, Some}
import gleam/pgo.{
  type Connection as DbConnection, type QueryError, type Returned,
  ConnectionUnavailable, ConstraintViolated, PostgresqlError,
  UnexpectedArgumentCount, UnexpectedArgumentType, UnexpectedResultType,
}
import gleam/result
import gleam/string
import youid/uuid.{type Uuid}

pub fn create_connection(path: Option(String)) -> Result(DbConnection, Nil) {
  let conf = config.get_db_settings(path)

  let connection =
    pgo.Config(
      ..pgo.default_config(),
      database: conf.db_name,
      host: conf.host,
      port: conf.port,
      ssl: conf.ssl,
      user: conf.user,
      password: Some(conf.password),
      pool_size: 1,
    )
    |> pgo.connect()

  Ok(connection)
}

pub fn create_tables(connection: DbConnection) -> Bool {
  case manage_create_tables(connection) {
    Ok(_) -> True
    Error(err) -> {
      let _ = log_error(err)
      False
    }
  }
}

fn manage_create_tables(connection: DbConnection) -> Result(Nil, QueryError) {
  let r = dynamic.dynamic
  use _ <- result.try(pgo.execute(create_table_users, connection, [], r))
  use _ <- result.try(pgo.execute(create_table_chats, connection, [], r))
  use _ <- result.try(pgo.execute(create_table_chats_users, connection, [], r))
  use _ <- result.try(pgo.execute(create_table_messages, connection, [], r))
  use _ <- result.try(pgo.execute(create_table_tokens, connection, [], r))
  Ok(Nil)
}

pub fn drop_tables(connection: DbConnection) -> Bool {
  case
    drop_all_tables
    |> pgo.execute(connection, [], dynamic.dynamic)
  {
    Ok(_) -> True
    Error(err) -> {
      let _ = log_error(err)
      False
    }
  }
}

pub fn log_error(error: QueryError) -> Result(a, Nil) {
  case error {
    ConstraintViolated(message, contraint, detail) ->
      io.println(
        "ConstraintViolated " <> message <> " " <> contraint <> " " <> detail,
      )
    PostgresqlError(code, name, message) ->
      io.println("PostgresqlError " <> message <> " " <> name <> " " <> code)
    UnexpectedArgumentCount(expected, got) ->
      io.println(
        "UnexpectedArgumentCount "
        <> int.to_string(expected)
        <> " "
        <> int.to_string(got),
      )
    UnexpectedArgumentType(expected, got) ->
      io.println("UnexpectedArgumentCount " <> expected <> " " <> got)
    UnexpectedResultType(decode_errors) -> {
      io.println("UnexpectedResultType")
      list.each(decode_errors, fn(x) {
        io.println("Expected: " <> x.expected <> " Found: " <> x.found)
        list.each(x.path, io.println)
      })
    }
    ConnectionUnavailable -> io.println("Connection is not available")
  }

  Error(Nil)
}

pub fn try_log_error(
  db_result: Result(Returned(a), QueryError),
  error_value: b,
  apply: fn(Returned(a)) -> Result(c, b),
) -> Result(c, b) {
  case db_result {
    Ok(val) -> apply(val)
    Error(err) -> {
      let _ = log_error(err)
      Error(error_value)
    }
  }
}

pub fn id_to_bit_array(uuid: Uuid) -> BitArray {
  let assert Ok(bits) =
    uuid
    |> uuid.to_string()
    |> string.replace("-", "")
    |> bit_array.base16_decode()

  bits
}

pub fn get_timestamp() -> Int {
  birl.utc_now()
  |> birl.to_unix()
}

const create_table_users = "
create table if not exists users (
id uuid primary key,
username varchar(32),
password bytea,
salt bytea,
created_at bigint);
"

const create_table_chats = "
create table if not exists chats (
id uuid primary key,
name varchar(32),
created_at bigint);
"

const create_table_chats_users = "
create table if not exists chats_users (
user_id uuid references users(id),
chat_id uuid references chats(id),
primary key(user_id, chat_id));
"

const create_table_messages = "
create table if not exists messages (
id uuid primary key,
user_id uuid references users(id) on delete cascade,
chat_id uuid references chats(id) on delete cascade,
content varchar(1000),
created_at bigint);
"

const create_table_tokens = "
create table if not exists tokens (
token uuid primary key,
user_id uuid references users(id) on delete cascade,
created_at bigint);
"

const drop_all_tables = "
drop table if exists users, chats, chats_users, messages, tokens;
"
