import gleam/option.{type Option, Some}
import gleam/pgo.{type IpVersion, Ipv4, Ipv6}
import gleam/result
import glenvy/dotenv
import glenvy/env

pub type DbSettings {
  DbSettings(
    db_name: String,
    host: String,
    port: Int,
    ssl: Bool,
    user: String,
    password: String,
    ip_version: IpVersion,
  )
}

pub fn get_db_settings(path_option: Option(String)) {
  let _ = case path_option {
    Some(path) -> dotenv.load_from(path)
    _ -> dotenv.load()
  }

  let db_name =
    env.get_string("DB_NAME")
    |> result.unwrap("chapp")

  let host =
    env.get_string("DB_HOST")
    |> result.unwrap("localhost")

  let port =
    env.get_int("DB_PORT")
    |> result.unwrap(5432)

  let ssl =
    env.get_bool("DB_SSL")
    |> result.unwrap(False)

  let user =
    env.get_string("DB_USER")
    |> result.unwrap("postgres")

  let password =
    env.get_string("DB_PASSWORD")
    |> result.unwrap("postgres")

  let ipversion =
    env.get("DB_IP_VERSION", parse_ip_version)
    |> result.unwrap(Ipv4)

  DbSettings(db_name, host, port, ssl, user, password, ipversion)
}

fn parse_ip_version(str: String) -> Result(IpVersion, Nil) {
  case str {
    "IPv4" -> Ok(Ipv4)
    "IPv6" -> Ok(Ipv6)
    _ -> Error(Nil)
  }
}
