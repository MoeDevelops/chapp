import chapp/api
import chapp/context.{type Context}
import chapp/database/user
import chapp/models
import gleam/http.{Get}
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context, username: String) -> Response {
  case req.method {
    Get -> get_user(ctx, username)
    _ -> wisp.method_not_allowed([Get])
  }
}

fn get_user(ctx: Context, username: String) -> Response {
  use user <- api.try(
    ctx.db
      |> user.get_user_by_username(username),
    wisp.not_found,
  )

  models.user_to_json(user)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
