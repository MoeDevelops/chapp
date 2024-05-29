import chapp/database/user
import chapp_test/database_test.{setup}
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

  let user =
    connection
    |> user.create_user(username, password)
    |> should.be_ok()

  connection
  |> user.get_user_id_by_auth(username, password)
  |> should.be_ok()
  |> should.equal(user.id)
}

pub fn delete_user_test() {
  let username = "Tester"
  let password = "securePw_1234444!"

  let connection = setup()

  let user =
    connection
    |> user.create_user(username, password)
    |> should.be_ok()

  connection
  |> user.delete_user(user.id)
  |> should.be_ok()

  connection
  |> user.get_user_id_by_auth(username, password)
  |> should.be_error()
}

pub fn get_user_by_username_test() {
  let username = "Tester"
  let password = "securePw_1234444!"

  let connection = setup()

  connection
  |> user.create_user(username, password)
  |> should.be_ok()

  connection
  |> user.get_user_by_username(username)
  |> should.be_ok()
}
