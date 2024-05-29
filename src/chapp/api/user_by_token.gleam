// import chapp/api
// import chapp/api/user.{user_to_json}
// import chapp/context.{type Context}
// import chapp/database/token
// import gleam/http.{Get}
// import gleam/json
// import wisp.{type Request, type Response}

// pub fn handle_request(req: Request, ctx: Context) -> Response {
//   case req.method {
//     Get -> get_user_by_token(req, ctx)
//     _ -> wisp.method_not_allowed([Get])
//   }
// }

// pub fn get_user_by_token(req: Request, ctx: Context) -> Response {
//   use token <- api.try(api.get_token(req), fn() { wisp.response(401) })

//   use user <- api.try(
//     ctx.db
//       |> token.get_user_by_token(token),
//     wisp.internal_server_error,
//   )

//   user_to_json(user)
//   |> json.to_string_builder()
//   |> wisp.json_response(200)
// }
