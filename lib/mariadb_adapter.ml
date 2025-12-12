open Result.Syntax
module Graph = Core_types.Graph
module Dsn = Database.Dsn
module E = Errors
module StringSet = Set.Make (String)

(** Interface to use to avoid double closing statements or connections by
    accident *)
module M = struct
  module Inner = Mariadb.Blocking
  module Stmt = Mariadb.Blocking.Stmt

  type stmt = Inner.Stmt.t
  type conn = Inner.t

  let execute stmt params =
    match Stmt.execute stmt params with
    | Ok res -> Ok res
    | Error (code, msg) ->
        Error
          (E.Execution_error
             ("Failed while executing a statement " ^ Int.to_string code ^ msg))

  let connect (s : Dsn.server) =
    match
      Inner.connect ~host:s.host ~user:s.user ~pass:s.pass ~db:s.database
        ~port:s.port ()
    with
    | Ok raw ->
        Ok raw
        (* I find the error that the mariadb lib returns is unhelpful as it returns always 2008: out of memory *)
    | Error (code, _) ->
        Error
          (E.Invalid_DSN
             ("Failed to connect to the database " ^ Int.to_string code))

  let with_conn conn_raw f =
    Fun.protect
      ~finally:(fun () -> ignore (Inner.close conn_raw))
      (fun () -> f conn_raw)

  let with_stmt conn query f =
    let stmt =
      match Inner.prepare conn query with
      | Ok s -> s
      | Error (code, err) ->
          failwith (Printf.sprintf "stmt prepare failed #%d: %s" code err)
    in
    Fun.protect
      ~finally:(fun () -> ignore (Inner.Stmt.close stmt))
      (fun () -> f stmt)

  (* Don't evaluate eagerly because the internal buffer in the MariaDB client is re used when consuming the rows so it ends up with the same value*)
  let stream res =
    let module F = struct
      exception E of Inner.error
    end in
    let rec next () =
      match Inner.Res.fetch (module Inner.Row.Map) res with
      | Ok (Some x) -> Seq.Cons (x, next)
      | Ok None -> Seq.Nil
      | Error (code, err) ->
          Printf.eprintf "MariaDB fetch error #%d: %s\n%!" code err;
          raise (F.E (code, err))
    in
    next
end

module MariadbBackend : Database.DBAdapter = struct
  type t = M.conn
  type error = E.t

  let spawn_connection dsn =
    match dsn with
    | Dsn.Server s -> (
        match M.connect s with
        | Ok (raw : M.Inner.t) -> Ok (raw, s.database)
        | Error e -> Error e)
    | Dsn.File _ -> failwith "Unimplemented"

  let find_opt tbl key = try Hashtbl.find tbl key with Not_found -> None

  let get_string row field_name default =
    match M.Inner.Row.StringMap.find_opt field_name row with
    | Some v -> (
        match M.Inner.Field.value v with `String s -> s | _ -> default)
    | None -> default

  let get_bool row field_name default =
    match M.Inner.Row.StringMap.find_opt field_name row with
    | Some v -> (
        match M.Inner.Field.value v with
        | `Int i -> i <> 0
        | `String "YES" -> true
        | `String "NO" -> false
        | _ -> default)
    | None -> default

  let get_string_opt row field_name =
    match M.Inner.Row.StringMap.find_opt field_name row with
    | Some v -> (
        match M.Inner.Field.value v with
        | `String s -> Some s
        | `Null -> None
        | _ -> None)
    | None -> None

  let query_map conn db_name ~query ~row_to_kv ~merge =
    M.with_stmt conn query @@ fun stmt ->
    let* res = M.execute stmt [| `String db_name |] in
    let map = Hashtbl.create 16 in

    Seq.iter
      (fun row ->
        let key, value = row_to_kv row in
        let existing = try Hashtbl.find map key with Not_found -> None in
        let merged = merge existing value in
        Hashtbl.replace map key merged)
      (M.stream res);

    Ok map

  let create_column_map conn db_name =
    let open Core_types in
    let query =
      "SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT \
       FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? ORDER BY \
       TABLE_NAME, ORDINAL_POSITION"
    in
    let row_to_kv row =
      let table_name = get_string row "TABLE_NAME" "" in
      let col_name = get_string row "COLUMN_NAME" "" in
      let col =
        {
          name = col_name;
          data_type = get_string row "DATA_TYPE" "";
          is_nullable = get_bool row "IS_NULLABLE" false;
          default = get_string_opt row "COLUMN_DEFAULT";
        }
      in
      (table_name, (col_name, col))
    in

    let merge existing (col_name, col) =
      let merged =
        match existing with
        | None -> ([ col ], StringSet.singleton col_name)
        | Some (cols, seen) ->
            if StringSet.mem col_name seen then (cols, seen)
            else (col :: cols, StringSet.add col_name seen)
      in
      Some merged
    in
    query_map conn db_name ~query ~row_to_kv ~merge

  let create_table_rows conn db_name =
    let tables_query =
      "SELECT TABLE_NAME, TABLE_TYPE FROM information_schema.TABLES WHERE \
       TABLE_SCHEMA = ? ORDER BY TABLE_NAME"
    in

    M.with_stmt conn tables_query @@ fun stmt ->
    let* res = M.execute stmt [| `String db_name |] in
    let table_rows =
      let rows = ref [] in
      Seq.iter
        (fun row ->
          let tbl_row =
            let tbl_name = get_string row "TABLE_NAME" "" in
            let tbl_type =
              match get_string row "TABLE_TYPE" "" with
              | "BASE TABLE" -> `BaseTable
              | "VIEW" -> `View
              | "SYSTEM VIEW" -> `SystemView
              | _ -> `BaseTable
            in
            (tbl_name, tbl_type)
          in
          rows := tbl_row :: !rows)
        (M.stream res);
      List.rev !rows
    in

    Ok table_rows

  let create_fk_map conn db_name =
    let open Core_types in
    let query =
      "SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, \
       REFERENCED_COLUMN_NAME FROM information_schema.KEY_COLUMN_USAGE WHERE \
       TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL ORDER BY \
       TABLE_NAME, COLUMN_NAME"
    in
    let row_to_kv row =
      let table_name = get_string row "TABLE_NAME" "" in
      let col_name = get_string row "COLUMN_NAME" "" in
      let fk =
        {
          column = col_name;
          references_table = get_string row "REFERENCED_TABLE_NAME" "";
          references_column = get_string row "REFERENCED_COLUMN_NAME" "";
        }
      in
      (table_name, (col_name, fk))
    in
    let merge existing (col_name, fk) =
      let merge =
        match existing with
        | None -> ([ fk ], StringSet.singleton col_name)
        | Some (fks, seen) ->
            if StringSet.mem col_name seen then (fks, seen)
            else (fk :: fks, StringSet.add col_name seen)
      in
      Some merge
    in
    query_map conn db_name ~query ~row_to_kv ~merge

  let create_index_map conn db_name =
    let open Core_types in
    let index_query =
      "SELECT TABLE_NAME, INDEX_NAME, NON_UNIQUE, COLUMN_NAME, SEQ_IN_INDEX, \
       INDEX_TYPE FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = ? \
       ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX"
    in

    M.with_stmt conn index_query @@ fun stmt ->
    let* res = M.execute stmt [| `String db_name |] in

    let index_map = Hashtbl.create 16 in
    Seq.iter
      (fun row ->
        let table_name = get_string row "TABLE_NAME" "" in
        let index_name = get_string row "INDEX_NAME" "" in
        let col_name = get_string row "COLUMN_NAME" "" in
        let is_unique = not (get_bool row "NON_UNIQUE" true) in
        let idx_type = parse_index_type (get_string row "INDEX_TYPE" "BTREE") in

        let table_indexes =
          try Hashtbl.find index_map table_name
          with Not_found ->
            let h = Hashtbl.create 8 in
            Hashtbl.replace index_map table_name h;
            h
        in
        let _, _, cols =
          try Hashtbl.find table_indexes index_name
          with Not_found -> (is_unique, idx_type, [])
        in
        Hashtbl.replace table_indexes index_name
          (is_unique, idx_type, cols @ [ col_name ]))
      (M.stream res);

    Ok index_map

  (* Asks the database for information about the tables from information_schema and returns a schema type*)
  let build_schema dsn =
    let open Core_types in
    let* conn, db_name = spawn_connection dsn in
    M.with_conn conn @@ fun conn ->
    let* table_rows = create_table_rows conn db_name in
    let* column_map = create_column_map conn db_name in
    let* fk_map = create_fk_map conn db_name in
    let* index_map = create_index_map conn db_name in

    M.Inner.library_end ();

    let tables =
      List.map
        (fun (name, table_type) ->
          let columns =
            match find_opt column_map name with
            | Some (cols, _) -> List.rev cols
            | None -> []
          in

          let foreign_keys =
            match find_opt fk_map name with
            | Some (fks, _) -> List.rev fks
            | None -> []
          in

          let table_indexes =
            match Hashtbl.find_opt index_map name with
            | Some tbl -> tbl
            | None -> Hashtbl.create 0
          in

          let primary_key =
            try
              let _, _, cols = Hashtbl.find table_indexes "PRIMARY" in
              cols
            with Not_found -> []
          in
          let indexes =
            Hashtbl.fold
              (fun idx_name (is_unique, idx_type, cols) acc ->
                if idx_name = "PRIMARY" then acc
                else
                  {
                    name = idx_name;
                    unique = is_unique;
                    index_type = idx_type;
                    columns = cols;
                  }
                  :: acc)
              table_indexes []
          in
          { name; primary_key; foreign_keys; columns; table_type; indexes })
        table_rows
    in

    let table_graph =
      List.fold_left
        (fun map tbl -> Graph.add tbl.name tbl map)
        Graph.empty tables
    in

    Ok { tables; table_graph }
end

module MariadbDB = Database.Backend (MariadbBackend)
