import chapp/database
import gleam/erlang/process.{type Selector}
import gleam/http/request.{type Request as HttpRequest}
import gleam/http/response.{type Response as HttpResponse}
import gleam/io
import gleam/option.{type Option, None}
import gleam/otp/actor.{type Next, Continue}
import gleam/pgo.{type Connection as DbConnection}
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage,
}
import wisp.{type Request, type Response}

pub type Context {
  Context(db: DbConnection)
}

pub fn create_handler(
  req: HttpRequest(Connection),
) -> HttpResponse(ResponseData) {
  let ctx = Context(database.create_connection("chapp"))
  case request.path_segments(req) {
    ["ws"] -> {
      mist.websocket(req, handle_ws_message, on_init, on_close)
    }
    _ -> {
      let secret_key_base = wisp.random_string(64)
      wisp.mist_handler(fn(x) { handle_request(x, ctx) }, secret_key_base)(req)
    }
  }
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case wisp.path_segments(req) {
    _ -> wisp.not_found()
  }
}

fn on_init(
  connection: WebsocketConnection,
) -> #(String, Option(Selector(String))) {
  #("Hello", None)
}

fn on_close(state: String) -> Nil {
  io.debug(state)
  Nil
}

fn handle_ws_message(
  state: String,
  connection: WebsocketConnection,
  message: WebsocketMessage(String),
) -> Next(String, String) {
  io.debug(state)
  io.debug(connection)
  io.debug(message)
  Continue(state, None)
}
