let split_once ~on s =
  match String.index_opt s on with
  | None -> None
  | Some i ->
      let a = String.sub s 0 i in
      let b = String.sub s (i + 1) (String.length s - i - 1) in
      Some (a, b)

let parse_scheme s =
  match split_once ~on:':' s with
  | None -> Error "Missing scheme (expected something://...)"
  | Some (scheme, rest) ->
      if String.length rest >= 2 && rest.[0] = '/' && rest.[1] = '/' then
        Ok (scheme, String.sub rest 2 (String.length rest - 2))
      else Error "Malformed scheme: expected // after scheme"

let parse_authority auth =
  let user, pass, rest =
    match split_once ~on:'@' auth with
    | None -> (None, None, auth)
    | Some (userinfo, after) ->
        let u, p =
          match split_once ~on:':' userinfo with
          | None -> (userinfo, None)
          | Some (u, p) -> (u, Some p)
        in
        (Some u, p, after)
  in

  let host, port =
    match split_once ~on:':' rest with
    | None -> (Some rest, None)
    | Some (h, pstr) ->
        let port = try Some (int_of_string pstr) with _ -> None in
        (Some h, port)
  in

  (user, pass, host, port)

module DSN = struct
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

  let fallback_env_string (field : string option) (env : string) : string =
    match field with
    | Some v when v <> "" -> v
    | _ -> (
        match Sys.getenv_opt env with
        | Some v -> v
        | None ->
            Printf.printf "No env var found: %s\n" env;
            "")

  let fallback_env_int (field : int option) (env : string) : int =
    match field with
    | Some v when v <> 0 -> v
    | _ -> (
        match Sys.getenv_opt env with
        | Some v -> int_of_string v
        | None ->
            Printf.printf "No env var found: %s\n" env;
            0)

  let finalize_server p : server =
    let prefix =
      match p.driver with Mariadb -> "MARIADB_" | Sqlite -> "SQLITE_"
    in
    {
      driver = p.driver;
      user = fallback_env_string p.user (prefix ^ "USER");
      pass = fallback_env_string p.pass (prefix ^ "PASSWORD");
      host = fallback_env_string p.host (prefix ^ "HOST");
      port = fallback_env_int p.port (prefix ^ "PORT");
      database = fallback_env_string p.database (prefix ^ "DATABASE");
    }

  let finalize = function
    | Server_partial p -> Server (finalize_server p)
    | File_partial { path = Some p } -> File { path = p }
    | File_partial { path = None } ->
        failwith "SQLite DSN missing path even after env resolution"

  let driver_of_string = function
    | "mariadb" | "mysql" -> Ok Mariadb
    | other -> Error ("Unknown driver: " ^ other)

  let parse_dsn input =
    match parse_scheme input with
    | Error e -> Error e
    | Ok (scheme, rest) -> (
        match driver_of_string (String.lowercase_ascii scheme) with
        | Error e -> Error e
        | Ok Mariadb ->
            let authority, dbname =
              match split_once ~on:'/' rest with
              | None -> (rest, None)
              | Some (a, d) ->
                  let db = if d = "" then None else Some d in
                  (a, db)
            in
            let user, pass, host, port = parse_authority authority in

            Ok
              (finalize
                 (Server_partial
                    {
                      driver = Mariadb;
                      user;
                      pass;
                      host;
                      port;
                      database = dbname;
                    }))
        | Ok Sqlite ->
            let path_opt = match rest with "" | "/" -> None | p -> Some p in
            Ok (finalize (File_partial { path = path_opt })))
end
