import birl
import chapp/config
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/pgo.{
  type Connection as DbConnection, type QueryError, ConnectionUnavailable,
  ConstraintViolated, PostgresqlError, UnexpectedArgumentCount,
  UnexpectedArgumentType, UnexpectedResultType,
}
import gleam/result

pub fn create_connection(database: String) -> Result(DbConnection, Nil) {
  use conf <- result.try(config.get_db_settings())

  let connection =
    pgo.Config(
      ..pgo.default_config(),
      database: database,
      host: conf.host,
      port: conf.port,
      ssl: conf.ssl,
      user: conf.user,
      password: Some(conf.password),
      pool_size: 15,
    )
    |> pgo.connect()

  Ok(connection)
}

pub fn create_tables(connection: DbConnection) -> Bool {
  case manage_create_tables(connection) {
    Ok(_) -> True
    Error(err) -> {
      log_error(err)
      False
    }
  }
}

fn manage_create_tables(connection: DbConnection) {
  use _ <- result.try(create_table_users(connection))
  use _ <- result.try(create_table_messages(connection))
  use _ <- result.try(create_table_tokens(connection))
  Ok(Nil)
}

fn create_table_users(connection: DbConnection) {
  create_table_users_sql
  |> pgo.execute(connection, [], dynamic.dynamic)
}

fn create_table_messages(connection: DbConnection) {
  create_table_messages_sql
  |> pgo.execute(connection, [], dynamic.dynamic)
}

fn create_table_tokens(connection: DbConnection) {
  create_table_tokens_sql
  |> pgo.execute(connection, [], dynamic.dynamic)
}

pub fn drop_tables(connection: DbConnection) -> Bool {
  case
    drop_tables_sql
    |> pgo.execute(connection, [], dynamic.dynamic)
  {
    Ok(_) -> True
    Error(err) -> {
      log_error(err)
      False
    }
  }
}

pub fn log_error(error: QueryError) -> Nil {
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
        io.println(x.expected <> x.found)
        list.each(x.path, io.println)
      })
    }
    ConnectionUnavailable -> io.println("Connection is not available")
  }
}

pub fn get_timestamp() -> Int {
  birl.utc_now()
  |> birl.to_unix()
}

const create_table_users_sql = "
create table if not exists users 
(username varchar(32) primary key, password char(256),
salt char(128), creation_timestamp bigint);
"

const create_table_messages_sql = "
create table if not exists messages
(id uuid primary key, 
author varchar(32) references Users(username),
recipient varchar(32) references Users(username), 
message_content varchar(1000), creation_timestamp bigint);
"

const create_table_tokens_sql = "
create table if not exists tokens
(token uuid primary key,
username varchar(32) references users(username),
creation_timestamp bigint);
"

const drop_tables_sql = "
drop table if exists users, messages, tokens;
"
