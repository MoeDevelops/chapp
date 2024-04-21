import gleam/bytes_builder
import gleam/erlang/process.{type Selector}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/option.{type Option, None}
import gleam/otp/actor.{type Next, Continue}
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage,
}

pub fn main() {
  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        ["ws"] ->
          mist.websocket(
            request: req,
            on_init: on_init,
            on_close: on_close,
            handler: handle_ws_message,
          )
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
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
