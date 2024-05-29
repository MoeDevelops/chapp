import chapp/database
import chapp/models.{type User, User}
import gleam/bit_array
import gleam/crypto.{Sha512}
import gleam/dynamic
import gleam/list
import gleam/pgo.{type Connection as DbConnection}
import youid/uuid.{type Uuid}

const create_user_sql = "
insert into
users (id, username, password, salt, created_at)
values ($1, $2, $3, $4, $5);
"

pub fn create_user(
  connection: DbConnection,
  username: String,
  password: String,
) -> Result(User, Nil) {
  let salt = crypto.strong_random_bytes(64)
  let password_bin = bit_array.from_string(password)
  let pw_hashed = hash_password(password_bin, salt)
  let id = uuid.v4()
  let created_at = database.get_timestamp()

  use _ <- database.try_log_error(
    create_user_sql
      |> pgo.execute(
        connection,
        [
          pgo.bytea(uuid.to_bit_array(id)),
          pgo.text(username),
          pgo.bytea(pw_hashed),
          pgo.bytea(salt),
          pgo.int(created_at),
        ],
        dynamic.dynamic,
      ),
    Nil,
  )

  Ok(User(id, username, created_at))
}

const verify_user_sql = "
select id, password, salt
from users
where username = $1;
"

pub fn get_user_id_by_auth(
  connection: DbConnection,
  username: String,
  password: String,
) -> Result(Uuid, Nil) {
  let password = bit_array.from_string(password)
  use db_result <- database.try_log_error(
    pgo.execute(
      verify_user_sql,
      connection,
      [pgo.text(username)],
      dynamic.tuple3(dynamic.bit_array, dynamic.bit_array, dynamic.bit_array),
    ),
    Nil,
  )

  case db_result.rows |> list.first() {
    Ok(#(id, pw_hash, salt)) -> {
      case hash_password(password, salt) == pw_hash {
        True -> uuid.from_bit_array(id)
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

const delete_user_sql = "
delete
from users
where id = $1;
"

pub fn delete_user(connection: DbConnection, id: Uuid) -> Result(Nil, String) {
  case
    delete_user_sql
    |> pgo.execute(
      connection,
      [pgo.bytea(uuid.to_bit_array(id))],
      dynamic.dynamic,
    )
  {
    Ok(_) -> Ok(Nil)
    Error(err) -> {
      let _ = database.log_error(err)
      Error("Error during database execution")
    }
  }
}

const get_user_by_username_sql = "
select id, username, created_at
from users
where username = $1
limit 1;
"

pub fn get_user_by_username(
  connection: DbConnection,
  username: String,
) -> Result(User, Nil) {
  case
    get_user_by_username_sql
    |> pgo.execute(
      connection,
      [pgo.text(username)],
      dynamic.tuple3(dynamic.bit_array, dynamic.string, dynamic.int),
    )
  {
    Ok(db_result) -> {
      case
        db_result.rows
        |> list.first()
      {
        Ok(#(id, username, created_at)) ->
          Ok(User(
            {
              let assert Ok(user_id) = uuid.from_bit_array(id)
              user_id
            },
            username,
            created_at,
          ))
        _ -> Error(Nil)
      }
    }
    Error(err) -> database.log_error(err)
  }
}

fn hash_password(password: BitArray, salt: BitArray) -> BitArray {
  let pw_and_salt = bit_array.append(password, salt)

  crypto.hash(Sha512, pw_and_salt)
}
