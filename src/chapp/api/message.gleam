import chapp/api
import chapp/context.{type Context}
import chapp/database/message.{type Message}
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

fn message_to_json(message: Message) {
  json.object([
    #("id", json.string(message.id)),
    #("author", json.string(message.author)),
    #("recipient", json.string(message.recipient)),
    #("message_content", json.string(message.message_content)),
    #("creation_timestamp", json.int(message.creation_timestamp)),
  ])
}

type IncomingMessage {
  IncomingMessage(token: String, recipient: String, content: String)
}

fn post_message(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  use incoming_message <- api.try(
    dynamic.decode3(
      IncomingMessage,
      dynamic.field("token", dynamic.string),
      dynamic.field("recipient", dynamic.string),
      dynamic.field("content", dynamic.string),
    )(json),
    wisp.unprocessable_entity,
  )

  use new_message <- api.try(
    ctx.db
      |> message.create_message(
      incoming_message.token,
      incoming_message.recipient,
      incoming_message.content,
    ),
    wisp.internal_server_error,
  )

  message_to_json(new_message)
  |> json.to_string_builder()
  |> wisp.json_response(201)
}

type Info {
  Info(token: String, user: String)
}

fn get_messages(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  use info <- api.try(
    dynamic.decode2(
      Info,
      dynamic.field("token", dynamic.string),
      dynamic.field("user", dynamic.string),
    )(json),
    wisp.unprocessable_entity,
  )

  use messages <- api.try(
    ctx.db
      |> message.get_messages(info.token, info.user),
    wisp.internal_server_error,
  )

  messages
  |> list.map(message_to_json)
  |> json.array(fn(x) { x })
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
