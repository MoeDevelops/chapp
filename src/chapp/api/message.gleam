import chapp/api
import chapp/context.{type Context}
import chapp/database/message
import chapp/models
import gleam/dynamic
import gleam/http.{Get, Post}
import gleam/json
import gleam/list
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> get_messages(req, ctx)
    Post -> post_message(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

type IncomingMessage {
  IncomingMessage(recipient: String, content: String)
}

fn post_message(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)
  use token <- api.try(api.get_token(req), fn() { wisp.response(401) })

  use incoming_message <- api.try(
    dynamic.decode2(
      IncomingMessage,
      dynamic.field("recipient", dynamic.string),
      dynamic.field("content", dynamic.string),
    )(json),
    wisp.unprocessable_entity,
  )

  use new_message <- api.try(
    ctx.db
      |> message.create_message(
      token,
      incoming_message.recipient,
      incoming_message.content,
    ),
    wisp.internal_server_error,
  )

  models.message_to_json(new_message)
  |> json.to_string_builder()
  |> wisp.json_response(201)
}

fn get_messages(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)
  use token <- api.try(api.get_token(req), fn() { wisp.response(401) })

  use user <- api.try(
    dynamic.decode1(fn(x) { x }, dynamic.field("user", dynamic.string))(json),
    wisp.unprocessable_entity,
  )

  use messages <- api.try(
    ctx.db
      |> message.get_messages(token, user),
    wisp.internal_server_error,
  )

  messages
  |> list.map(models.message_to_json)
  |> json.array(fn(x) { x })
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
