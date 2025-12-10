module DSN : sig
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

  val parse_dsn : string -> (t, string) result
end
