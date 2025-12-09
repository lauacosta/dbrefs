open Dbrefs
open Dbrefs.Analyzer

let main () =
  let open Core_types in
  let schema = Database.build_schema "demo" in
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

  Yojson.Safe.pretty_to_channel stdout (Export_types.export_to_yojson res)

let () = main ()
