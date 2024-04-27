import chapp/api/login
import chapp/api/message
import chapp/api/register
import chapp/api/user
import chapp/context.{type Context, Context}
import chapp/database
import gleam/erlang/process.{type Selector}
import gleam/http/request.{type Request as HttpRequest}
import gleam/http/response.{type Response as HttpResponse}
import gleam/io
import gleam/option.{type Option, None}
import gleam/otp/actor.{type Next, Continue}
import gleam/result
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage,
}
import wisp.{type Request, type Response}

pub fn create_handler(
  path: Option(String),
) -> Result(fn(HttpRequest(Connection)) -> HttpResponse(ResponseData), Nil) {
  use connection <- result.try(database.create_connection(path))
  database.create_tables(connection)
  let ctx = Context(connection)

  Ok(fn(req: HttpRequest(Connection)) { handle_request(req, ctx) })
}

fn handle_request(
  req: HttpRequest(Connection),
  ctx: Context,
) -> HttpResponse(ResponseData) {
  case request.path_segments(req) {
    ["ws"] -> {
      handle_websocket(req, ctx)
    }
    _ -> {
      let secret_key_base = wisp.random_string(64)
      wisp.mist_handler(fn(x) { handle_http_request(x, ctx) }, secret_key_base)(
        req,
      )
    }
  }
}

fn handle_websocket(
  req: HttpRequest(Connection),
  _ctx: Context,
) -> HttpResponse(ResponseData) {
  mist.websocket(req, handle_ws_message, on_init, on_close)
}

fn handle_http_request(req: Request, ctx: Context) -> Response {
  case wisp.path_segments(req) {
    ["messages"] -> message.handle_request(req, ctx)
    ["register"] -> register.handle_request(req, ctx)
    ["login"] -> login.handle_request(req, ctx)
    ["user"] -> user.handle_request(req, ctx)
    _ -> wisp.not_found()
  }
}

fn on_init(
  _connection: WebsocketConnection,
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
