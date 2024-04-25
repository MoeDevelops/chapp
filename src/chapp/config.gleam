import gleam/pgo.{type IpVersion, Ipv4, Ipv6}
import gleam/result
import glenvy/dotenv
import glenvy/env

pub type DbSettings {
  DbSettings(
    host: String,
    port: Int,
    ssl: Bool,
    user: String,
    password: String,
    ip_version: IpVersion,
  )
}

pub fn get_db_settings() {
  let _ = dotenv.load()
  use host <- result.try(env.get_string("DB_HOST"))
  use port <- result.try(env.get_int("DB_PORT"))
  use ssl <- result.try(env.get_bool("DB_SSL"))
  use user <- result.try(env.get_string("DB_USER"))
  use password <- result.try(env.get_string("DB_PASSWORD"))
  use ipversion <- result.try(env.get("DB_IP_VERSION", parse_ip_version))

  Ok(DbSettings(host, port, ssl, user, password, ipversion))
}

fn parse_ip_version(str: String) -> Result(IpVersion, Nil) {
  case str {
    "IPv4" -> Ok(Ipv4)
    "IPv6" -> Ok(Ipv6)
    _ -> Error(Nil)
  }
}
