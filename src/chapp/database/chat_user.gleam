import chapp/database
import chapp/models.{type Chat, Chat}
import gleam/dynamic
import gleam/list
import gleam/pgo.{type Connection as DbConnection}
import youid/uuid.{type Uuid}

const add_user_to_chat_sql = "
insert into
chats_users (chat_id, user_id)
values ($1, $2);
"

pub fn add_user_to_chat(
  connection: DbConnection,
  chat_id: Uuid,
  user_id: Uuid,
) -> Result(Nil, Nil) {
  use _ <- database.try_log_error(
    pgo.execute(
      add_user_to_chat_sql,
      connection,
      [
        pgo.bytea(uuid.to_bit_array(chat_id)),
        pgo.bytea(uuid.to_bit_array(user_id)),
      ],
      dynamic.dynamic,
    ),
    Nil,
  )

  Ok(Nil)
}

const get_chats_by_user_id_sql = "
select c.id, c.name, c.created_at
from chats c
inner join chats_users uc on uc.chat_id = c.id
inner join users u on u.id = uc.user_id
where u.id = $1
limit 500;
"

pub fn get_chats_by_user_id(
  connection: DbConnection,
  user_id: Uuid,
) -> Result(List(Chat), Nil) {
  use db_result <- database.try_log_error(
    pgo.execute(
      get_chats_by_user_id_sql,
      connection,
      [pgo.bytea(uuid.to_bit_array(user_id))],
      dynamic.tuple3(dynamic.bit_array, dynamic.string, dynamic.int),
    ),
    Nil,
  )

  Ok(
    db_result.rows
    |> list.map(fn(tp) {
      let #(id, name, created_at) = tp
      Chat(
        {
          let assert Ok(id) = uuid.from_bit_array(id)
          id
        },
        name,
        created_at,
      )
    }),
  )
}
