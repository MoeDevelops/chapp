import chapp/api
import chapp/context.{type Context}
import chapp/database/message
import chapp/database/token
import gleam/http.{Get}
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> get_chats(req, ctx)
    _ -> wisp.method_not_allowed([Get])
  }
}

fn get_chats(req: Request, ctx: Context) {
  use token <- api.try(api.get_token(req), fn() { wisp.response(401) })

  use user <- api.try(
    ctx.db
      |> token.get_user_by_token(token),
    wisp.not_found,
  )

  use chats <- api.try(
    ctx.db
      |> message.get_chats(user.username),
    wisp.internal_server_error,
  )

  json.array(chats, fn(x) { json.string(x) })
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
