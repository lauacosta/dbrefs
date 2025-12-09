open Dbrefs
open Dbrefs.Json
open Dbrefs.Analyzer

let main () =
  let fk = Database.key_column_usage "demo" in
  let rfk = Analyzer.build_rfk fk in
  let orphans = Analyzer.orphan_tables fk rfk in

  let junctions =
    Graph.fold
      (fun t _ acc -> if Analyzer.is_junction_table fk t then t :: acc else acc)
      fk []
  in

  let heavy = Analyzer.reference_heavy rfk 2 in

  let json =
    Json_export.export ~fk ~rfk ~orphans ~junctions ~reference_heavy:heavy
  in

  Yojson.Safe.pretty_to_channel stdout json;

  let tables = Database.tables_information_schema "demo" in
  let json = `List (List.map Database.table_info_to_yojson tables) in
  print_endline (Yojson.Safe.pretty_to_string json)

let () = main ()
