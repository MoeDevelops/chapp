import chapp/database/token
import chapp/database/user
import chapp_test/database_test.{setup}
import gleeunit/should

pub fn create_token_pair_test() {
  let username = "Testaaaa"
  let password = "Passworrrdddd123123"
  let connection = setup()

  connection
  |> user.create_user(username, password)
  |> should.be_ok()
  |> token.verify_token(connection, _)
  |> should.be_true()

  let user =
    connection
    |> user.get_user_by_username(username)
    |> should.be_ok()

  connection
  |> token.create_token_pair(user.id)
  |> should.be_ok()
  |> token.verify_token(connection, _)
  |> should.be_true()
}

pub fn verify_token_test() {
  let connection = setup()

  connection
  |> user.create_user("Tester", "securePw_123!")
  |> should.be_ok()
  |> token.verify_token(connection, _)
  |> should.be_true()
}

pub fn get_user_by_token_test() {
  let username = "Tester"
  let connection = setup()

  let user =
    connection
    |> user.create_user(username, "securePw_123!")
    |> should.be_ok()
    |> token.token()
    |> token.get_user_by_token(connection, _)
    |> should.be_ok()

  user.username
  |> should.equal(username)
}
