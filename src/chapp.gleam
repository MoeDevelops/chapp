import chapp/router
import gleam/erlang/process
import gleam/result
import mist

pub fn main() -> Result(Nil, Nil) {
  use handler <- result.try(router.create_handler())

  let assert Ok(_) =
    handler
    |> mist.new()
    |> mist.port(3000)
    |> mist.start_http()

  Ok(process.sleep_forever())
}
