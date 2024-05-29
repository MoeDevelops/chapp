import chapp/api
import chapp/context.{type Context}
import chapp/database/token
import chapp/database/user
import gleam/dynamic
import gleam/http.{Post}
import gleam/json
import wisp.{type Request, type Response}
import youid/uuid

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

  use user_id <- api.try(
    user.get_user_id_by_auth(
      ctx.db,
      incoming_user.username,
      incoming_user.password,
    ),
    wisp.internal_server_error,
  )

  use token <- api.try(
    token.create_token(ctx.db, user_id),
    wisp.internal_server_error,
  )

  json.object([#("token", json.string(uuid.to_string(token)))])
  |> json.to_string_builder()
  |> wisp.json_response(201)
}
