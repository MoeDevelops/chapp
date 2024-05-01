import chapp/api
import chapp/context.{type Context}
import chapp/database/user
import chapp/models.{type User}
import gleam/dynamic
import gleam/http.{Delete}
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case req.method {
    Delete -> delete_user(req, ctx)
    _ -> wisp.method_not_allowed([Delete])
  }
}

pub fn user_to_json(user: User) {
  json.object([
    #("username", json.string(user.username)),
    #("creation_timestamp", json.int(user.creation_timestamp)),
  ])
}

fn delete_user(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  use token <- api.try(
    dynamic.decode1(fn(x) { x }, dynamic.field("token", dynamic.string))(json),
    wisp.unprocessable_entity,
  )

  case
    ctx.db
    |> user.delete_user(token)
  {
    Ok(_) -> wisp.ok()
    Error(err) ->
      json.object([#("Error", json.string(err))])
      |> json.to_string_builder
      |> wisp.json_response(406)
  }
}
