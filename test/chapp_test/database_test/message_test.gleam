// import chapp/database/message
// import chapp/database/user
// import chapp/models.{type TokenPair}
// import chapp_test/database_test.{setup}
// import gleam/pgo.{type Connection as DbConnection}
// import gleeunit/should

// const user1_name = "User1"

// const user1_pw = "PasswordForUser1"

// const user2_name = "User2"

// const user2_pw = "PasswordForUser2"

// fn create_users(connection: DbConnection) -> TokenPair {
//   let token_user1 =
//     connection
//     |> user.create_user(user1_name, user1_pw)
//     |> should.be_ok

//   connection
//   |> user.create_user(user2_name, user2_pw)
//   |> should.be_ok

//   token_user1
// }

// pub fn create_message_test() {
//   let connection = setup()
//   let token = create_users(connection).token

//   let content = "Hello User2, how are you doing?"

//   connection
//   |> message.create_message(token, user2_name, content)
//   |> should.be_ok()
// }
