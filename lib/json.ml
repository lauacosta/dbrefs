module Graph = Core_types.Graph

type fk_graph = Core_types.fk_graph

module Json_export = struct
  let yojson_of_graph (g : fk_graph) =
    `Assoc
      (Graph.fold
         (fun key refs acc ->
           (key, `List (List.map (fun r -> `String r) refs)) :: acc)
         g [])

  let yojson_of_in_degree rfk =
    `Assoc
      (Graph.fold
         (fun table refs acc -> (table, `Int (List.length refs)) :: acc)
         rfk [])

  let export ~(fk : fk_graph) ~(rfk : fk_graph) ~(orphans : string list)
      ~(junctions : string list) ~(reference_heavy : string list) =
    `Assoc
      [
        ("fk_graph", yojson_of_graph fk);
        ("rfk_graph", yojson_of_graph rfk);
        ("in_degree", yojson_of_in_degree rfk);
        ("orphan_tables", `List (List.map (fun s -> `String s) orphans));
        ("junction_tables", `List (List.map (fun s -> `String s) junctions));
        ( "reference_heavy",
          `List (List.map (fun s -> `String s) reference_heavy) );
      ]
end
