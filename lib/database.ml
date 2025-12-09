open Printf
open Analyzer
module M = Mariadb.Blocking

type table_type = [ `SystemView | `View | `BaseTable ] [@@deriving yojson]

type table_info = { table_name : string; table_type : table_type }
[@@deriving yojson]

let or_die where = function
  | Ok r -> r
  | Error (i, e) -> failwith @@ sprintf "%s: (%d) %s" where i e

let spawn_connection ?(host = "127.0.0.1") ?(user = "root") ?(pass = "secret")
    () =
  M.connect ~host ~user ~pass () |> or_die "connect"

let stream res =
  let module F = struct
    exception E of M.error
  end in
  let rec next () =
    match M.Res.fetch (module M.Row.Map) res with
    | Ok (Some x) -> Seq.Cons (x, next)
    | Ok None -> Seq.Nil
    | Error (code, err) ->
        Printf.eprintf "MariaDB fetch error #%d: %s\n%!" code err;
        raise (F.E (code, err))
  in
  next

let update_graph graph row =
  let tbl =
    match M.Row.StringMap.find_opt "TABLE_NAME" row with
    | Some v -> (
        match M.Field.value v with `String s -> s | _ -> "<unknown-table>")
    | None -> "<missing TABLE_NAME>"
  in
  let refd =
    match M.Row.StringMap.find_opt "REFERENCED_TABLE_NAME" row with
    | Some v -> ( match M.Field.value v with `String s -> [ s ] | _ -> [])
    | None -> []
  in

  let existing =
    match Graph.find_opt tbl graph with Some l -> l | None -> []
  in

  graph |> Graph.add tbl (existing @ refd)

let update_tables_list (list : table_info list) row =
  let tbl =
    match M.Row.StringMap.find_opt "TABLE_NAME" row with
    | Some v -> (
        match M.Field.value v with `String s -> s | _ -> "<unknown-table>")
    | None -> "<missing TABLE_NAME>"
  in
  let t_type_opt =
    match M.Row.StringMap.find_opt "TABLE_TYPE" row with
    | Some v -> (
        match M.Field.value v with
        | `String s -> (
            match s with
            | "BASE TABLE" -> Some `BaseTable
            | "VIEW" -> Some `View
            | "SYSTEM VIEW" -> Some `SystemView
            | _ -> None)
        | _ -> None)
    | None -> None
  in
  match t_type_opt with
  | Some t_type -> { table_name = tbl; table_type = t_type } :: list
  | None -> list

let key_column_usage db_name =
  let conn = spawn_connection () in

  let query =
    "SELECT\n\
    \  TABLE_NAME,\n\
    \  REFERENCED_TABLE_NAME\n\
     FROM information_schema.KEY_COLUMN_USAGE\n\
     WHERE TABLE_SCHEMA = ? \n"
  in

  let stmt = M.prepare conn query |> or_die "prepare" in
  let res = M.Stmt.execute stmt [| `String db_name |] |> or_die "exec" in

  assert (M.Res.affected_rows res = M.Res.num_rows res);

  let rows = stream res in
  let graph = Seq.fold_left update_graph Graph.empty rows in

  M.Stmt.close stmt |> or_die "stmt close";
  M.close conn;
  M.library_end ();

  graph

let tables_information_schema db_name =
  let conn = spawn_connection () in

  let query =
    "SELECT\n\
    \  TABLE_NAME,\n\
    \  TABLE_TYPE\n\
     FROM information_schema.TABLES\n\
     WHERE TABLE_SCHEMA = ? \n"
  in

  let stmt = M.prepare conn query |> or_die "prepare" in
  let res = M.Stmt.execute stmt [| `String db_name |] |> or_die "exec" in

  assert (M.Res.affected_rows res = M.Res.num_rows res);

  let rows = stream res in
  let list = Seq.fold_left update_tables_list [] rows in

  M.Stmt.close stmt |> or_die "stmt close";
  M.close conn;
  M.library_end ();

  list
