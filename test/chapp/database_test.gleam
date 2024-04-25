import chapp/database
import gleam/pgo.{type Connection as DbConnection}
import gleeunit/should

pub const db_name = "chapp_test"

pub fn setup() -> DbConnection {
  let connection =
    database.create_connection(db_name)
    |> should.be_ok()

  let _ = database.drop_tables(connection)

  database.create_tables(connection)
  |> should.be_true()

  connection
}
