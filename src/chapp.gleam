import chapp/router
import gleam/erlang/process
import mist

pub fn main() {
  let assert Ok(_) =
    router.create_handler
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}
