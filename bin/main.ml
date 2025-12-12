open Result.Syntax
open Dbrefs
open Dbrefs.Analyzer
open Cmdliner
open Cmdliner.Term.Syntax
module Mariadb = Mariadb_adapter.MariadbDB
module Dsn = Database.Dsn

let document_db (dsn : Dsn.t) =
  let open Core_types in
  let* schema = Mariadb.build_schema dsn in
  let json = `List (List.map Dbrefs.Core_types.table_to_yojson schema.tables) in

  Yojson.Safe.pretty_to_channel stdout json;

  let fk =
    Graph.map
      (fun t -> List.map (fun fk -> fk.references_table) t.foreign_keys)
      schema.table_graph
  in

  let rfk = Analyzer.build_rfk fk in
  let orphans_tables = Analyzer.orphan_tables fk rfk in

  let junction_tables =
    Graph.fold
      (fun t _ acc -> if Analyzer.is_junction_table fk t then t :: acc else acc)
      fk []
  in

  let reference_heavy = Analyzer.reference_heavy rfk 2 in

  let res =
    Export_types.export ~fk ~rfk ~reference_heavy ~junction_tables
      ~orphans_tables
  in

  Yojson.Safe.pretty_to_channel stdout (Export_types.export_to_yojson res);
  Ok ()

(* Yojson.Safe.pretty_to_channel stdout (Dsn.to_yojson dsn) *)

let dsn =
  let doc = "Connection string to the database" in
  Arg.(required & pos 0 (some string) None & info [] ~doc ~docv:"database_url")

let document_db_cmd =
  let doc = "Generates a static site from the database" in
  let man =
    [
      `S Manpage.s_bugs;
      `P "Email bug reports to <acostaquintanalautaro@gmail.com>";
    ]
  in
  Cmd.make (Cmd.info "dbrefs" ~version:"v0.0.1" ~doc ~man)
  @@ let+ dsn = dsn in
     match Dsn.parse_dsn dsn with
     | Error e ->
         prerr_endline (Errors.pp_error e);
         exit 1
     | Ok dsn -> (
         match document_db dsn with
         | Ok () -> ()
         | Error err ->
             prerr_endline (Errors.pp_error err);
             exit 1)

let main () = Cmd.eval document_db_cmd
let () = if !Sys.interactive then () else exit (main ())
