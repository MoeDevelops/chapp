import chapp/database/user
import chapp/database_test.{setup}
import gleeunit/should

pub fn create_user_test() {
  setup()
  |> user.create_user("Tester", "securePw_123!")
  |> should.be_some()
}
