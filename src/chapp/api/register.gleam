import chapp/api
import chapp/context.{type Context}
import chapp/database/user
import chapp/models
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

  use user <- api.try(
    user.create_user(ctx.db, incoming_user.username, incoming_user.password),
    wisp.internal_server_error,
  )

  models.user_to_json(user)
  |> json.to_string_builder()
  |> wisp.json_response(201)
}
