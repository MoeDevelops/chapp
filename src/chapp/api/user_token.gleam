import chapp/api
import chapp/context.{type Context}
import chapp/database/token
import chapp/models
import gleam/http.{Get}
import gleam/json
import wisp.{type Request, type Response}
import youid/uuid

pub fn handle_request(req: Request, ctx: Context, token: String) -> Response {
  case req.method {
    Get -> get_user_by_token(ctx, token)
    _ -> wisp.method_not_allowed([Get])
  }
}

pub fn get_user_by_token(ctx: Context, token: String) -> Response {
  use token <- api.try(uuid.from_string(token), wisp.unprocessable_entity)

  use user <- api.try(token.get_user_by_token(ctx.db, token), wisp.not_found)

  models.user_to_json(user)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
