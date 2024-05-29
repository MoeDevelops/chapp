import chapp/context.{type Context}
import chapp/database/chat
import gleam/http.{Get, Post}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> post_chat(req, ctx)
    Get -> get_chats(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn post_chat(req: Request, ctx: Context) -> Response {
  todo
}

fn get_chats(req: Request, ctx: Context) {
  todo
}
