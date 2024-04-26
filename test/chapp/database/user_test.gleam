import chapp/database/token
import chapp/database/user
import chapp/database_test.{setup}
import gleeunit/should

pub fn create_user_test() {
  setup()
  |> user.create_user("Tester", "securePw_123!")
  |> should.be_ok()
}

pub fn login_test() {
  let username = "Tester"
  let password = "securePw_1234444!"

  let connection = setup()

  connection
  |> user.create_user(username, password)
  |> should.be_ok()

  connection
  |> user.login(username, password)
  |> should.be_ok()
}

pub fn delete_user_test() {
  let username = "Tester"
  let password = "securePw_1234444!"

  let connection = setup()

  connection
  |> user.create_user(username, password)
  |> should.be_ok()
  |> token.token()
  |> user.delete_user(connection, _)
  |> should.be_ok()

  connection
  |> user.login(username, password)
  |> should.be_error()
}

pub fn get_user_test() {
  let username = "Tester"
  let password = "securePw_1234444!"

  let connection = setup()

  connection
  |> user.create_user(username, password)
  |> should.be_ok()

  connection
  |> user.get_user(username)
  |> should.be_ok()
}
