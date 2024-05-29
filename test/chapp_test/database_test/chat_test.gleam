import chapp/database/chat
import chapp_test/database_test.{setup}
import gleeunit/should
import youid/uuid

pub fn create_chat_test() {
  let connection = setup()

  connection
  |> chat.create_chat("TestChat")
  |> should.be_ok()
}

pub fn get_chat_by_id_test() {
  let connection = setup()

  let chat =
    connection
    |> chat.create_chat("TestChat")
    |> should.be_ok()

  connection
  |> chat.get_chat_by_id(chat.id |> uuid.from_string() |> should.be_ok())
  |> should.be_ok()
}