import chapp/api
import chapp/context.{type Context}
import chapp/database/token
import gleam/dynamic
import gleam/http.{Post}
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> get_user_by_token(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

pub fn get_user_by_token(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  use token <- api.try(
    dynamic.decode1(fn(x) { x }, dynamic.field("token", dynamic.string))(json),
    wisp.unprocessable_entity,
  )

  use user <- api.try(
    ctx.db
      |> token.get_user_by_token(token),
    wisp.internal_server_error,
  )

  json.object([#("username", json.string(user))])
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
