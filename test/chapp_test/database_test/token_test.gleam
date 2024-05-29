import chapp/database/token
import chapp/database/user
import chapp_test/database_test.{setup}
import gleeunit/should

pub fn create_token_test() {
  let username = "Testaaaa"
  let password = "Passworrrdddd123123"
  let connection = setup()

  let user =
    connection
    |> user.create_user(username, password)
    |> should.be_ok()

  connection
  |> token.create_token(user.id)
  |> should.be_ok
}

pub fn verify_token_test() {
  let connection = setup()

  let user =
    connection
    |> user.create_user("Tester", "securePw_123!")
    |> should.be_ok()

  let token =
    connection
    |> token.create_token(user.id)
    |> should.be_ok()

  connection
  |> token.verify_token(user.id, token)
  |> should.be_ok()
}

pub fn get_user_by_token_test() {
  let username = "Tester"
  let connection = setup()

  let user =
    connection
    |> user.create_user(username, "securePw_123!")
    |> should.be_ok()

  connection
  |> token.create_token(user.id)
  |> should.be_ok()
  |> token.get_user_by_token(connection, _)
  |> should.be_ok()
  |> should.equal(user)
}
