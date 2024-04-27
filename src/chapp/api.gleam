pub fn try(res: Result(a, b), on_error: fn() -> c, apply fun: fn(a) -> c) -> c {
  case res {
    Ok(val) -> fun(val)
    _ -> on_error()
  }
}
