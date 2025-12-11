module E = Errors

val or_die : string -> ('a, E.t) result -> 'a

module Dsn : sig
  type driver = Mariadb | Sqlite [@@deriving yojson]

  type server = {
    driver : driver;
    user : string;
    pass : string;
    host : string;
    port : int;
    database : string;
  }
  [@@deriving yojson]

  type t = Server of server | File of { path : string } [@@deriving yojson]

  val parse_dsn : string -> (t, E.t) result
end

module type DBAdapter = sig
  type t
  type error = E.t

  val build_schema : Dsn.t -> (Core_types.schema, error) result
end

module Backend : (B : DBAdapter) -> sig
  type t = B.t
  type error = E.t

  val build_schema : Dsn.t -> (Core_types.schema, error) result
end
