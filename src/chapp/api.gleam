import gleam/list
import wisp.{type Request}

pub fn try(res: Result(a, b), on_error: fn() -> c, apply fun: fn(a) -> c) -> c {
  case res {
    Ok(val) -> fun(val)
    _ -> on_error()
  }
}

pub fn get_token(req: Request) -> Result(String, Nil) {
  let token =
    req.headers
    |> list.key_find("token")

  case token {
    Ok(token) -> Ok(token)
    Error(_) -> Error(Nil)
  }
}
