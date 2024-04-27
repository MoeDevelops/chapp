import gleam/pgo.{type Connection as DbConnection}

pub type Context {
  Context(db: DbConnection)
}
