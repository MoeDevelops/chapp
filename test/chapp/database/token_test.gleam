import chapp/database/token
import chapp/database/user
import chapp/database_test.{setup}
import gleeunit/should

pub fn verify_token_test() {
  let connection = setup()

  connection
  |> user.create_user("Tester", "securePw_123!")
  |> should.be_some()
  |> token.verify_token(connection, _)
  |> should.be_true()
}

pub fn get_user_by_token_test() {
  let username = "Tester"
  let connection = setup()

  connection
  |> user.create_user(username, "securePw_123!")
  |> should.be_some()
  |> token.token()
  |> token.get_user_by_token(connection, _)
  |> should.be_some()
  |> should.equal(username)
}
