import chapp/database/chat
import chapp/database/chat_user
import chapp/database/user
import chapp_test/database_test.{setup}
import gleeunit/should

pub fn add_user_to_chat_test() {
  let connection = setup()

  let user =
    connection
    |> user.create_user("Test1232345", "Password123543")
    |> should.be_ok()

  let chat =
    connection
    |> chat.create_chat("aChat")
    |> should.be_ok()

  connection
  |> chat_user.add_user_to_chat(chat.id, user.id)
  |> should.be_ok()
}
