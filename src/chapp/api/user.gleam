import chapp/api
import chapp/context.{type Context}
import chapp/database/user
import gleam/dynamic
import gleam/http.{Delete, Get}
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> get_user(req, ctx)
    Delete -> delete_user(req, ctx)
    _ -> wisp.method_not_allowed([Get, Delete])
  }
}

fn get_user(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  use username <- api.try(
    dynamic.decode1(fn(x) { x }, dynamic.field("username", dynamic.string))(
      json,
    ),
    wisp.unprocessable_entity,
  )

  use user <- api.try(
    ctx.db
      |> user.get_user(username),
    wisp.internal_server_error,
  )

  json.object([
    #("username", json.string(user.username)),
    #("creation_timestamp", json.int(user.creation_timestamp)),
  ])
  |> json.to_string_builder()
  |> wisp.json_response(201)
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
