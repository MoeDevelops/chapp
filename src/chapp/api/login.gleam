import chapp/api
import chapp/context.{type Context}
import chapp/database/user
import gleam/dynamic
import gleam/http.{Post}
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> post_user(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

type IncomingUser {
  IncomingUser(username: String, password: String)
}

fn post_user(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  use incoming_user <- api.try(
    dynamic.decode2(
      IncomingUser,
      dynamic.field("username", dynamic.string),
      dynamic.field("password", dynamic.string),
    )(json),
    wisp.unprocessable_entity,
  )

  use new_token_pair <- api.try(
    ctx.db
      |> user.login(incoming_user.username, incoming_user.password),
    wisp.internal_server_error,
  )

  json.object([
    #("user_id", json.string(new_token_pair.user_id)),
    #("token", json.string(new_token_pair.token)),
  ])
  |> json.to_string_builder()
  |> wisp.json_response(201)
}
