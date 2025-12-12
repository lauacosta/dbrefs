open Result.Syntax
open Cmdliner
open Cmdliner.Term.Syntax
open Analyzer
module Dsn = Database.Dsn

let database = (module Dbref_mariadb : Database.Database)

module Database = (val database)

let document_db (dsn : Dsn.t) =
  let open Core_types in
  let* schema_data = Database.build_schema dsn in
  let derived_data = Analyzer.derive_data schema_data in

  Yojson.Safe.pretty_to_channel stdout
    (Payload.to_yojson { schema_data; derived_data });

  Ok ()

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

let run () = Cmd.eval document_db_cmd
