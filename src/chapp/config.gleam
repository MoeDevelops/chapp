import gleam/io
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
  io.println("Trying to load .env")
  let _ = dotenv.load()
  io.println("Loaded .env")

  io.println("Trying to load host")
  use host <- result.try(env.get_string("HOST"))
  io.println("Loaded host")

  io.println("Trying to load port")
  use port <- result.try(env.get_int("PORT"))
  io.println("Loaded port")

  io.println("Trying to load ssl")
  use ssl <- result.try(env.get_bool("SSL"))
  io.println("Loaded ssl")

  io.println("Trying to load user")
  use user <- result.try(env.get_string("USER"))
  io.println("Loaded user")

  io.println("Trying to load password")
  use password <- result.try(env.get_string("PASSWORD"))
  io.println("Loaded password")

  io.println("Trying to load version")
  use ipversion <- result.try(env.get("IP_VERSION", parse_ip_version))
  io.println("Loaded IP Version")

  Ok(DbSettings(host, port, ssl, user, password, ipversion))
}

fn parse_ip_version(str: String) -> Result(IpVersion, Nil) {
  case str {
    "IPv4" -> Ok(Ipv4)
    "IPv6" -> Ok(Ipv6)
    _ -> Error(Nil)
  }
}
