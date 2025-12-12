module E = Errors

val or_die : string -> ('a, E.t) result -> 'a
val split_once : on:char -> string -> (string * string) option
val parse_scheme : string -> (string * string, E.t) result

val parse_authority :
  string -> string option * string option * string option * int option

module Dsn : sig
  type driver = Mariadb | Sqlite

  type server = {
    driver : driver;
    user : string;
    pass : string;
    host : string;
    port : int;
    database : string;
  }

  type t = Server of server | File of { path : string }

  type partial_server = {
    driver : driver;
    user : string option;
    pass : string option;
    host : string option;
    port : int option;
    database : string option;
  }

  type partial =
    | Server_partial of partial_server
    | File_partial of { path : string option }

  val fallback_env_string : string option -> string -> string
  val fallback_env_int : int option -> string -> int
  val finalize_server : partial_server -> server
  val finalize : partial -> t
  val driver_of_string : string -> (driver, E.t) result
  val parse_dsn : string -> (t, E.t) result
end

module type Database = sig
  type t
  type error = E.t

  val build_schema : Dsn.t -> (Core_types.SchemaData.t, error) result
end
