module Analyzer = struct
  open Core_types

  type t = FkGraph.t

  let build_rfk (g : t) : t =
    let g = g.graph in
    {
      graph =
        Graph.fold
          (fun src refs acc ->
            List.fold_left
              (fun acc dst ->
                let existing =
                  match Graph.find_opt dst acc with Some l -> l | None -> []
                in
                Graph.add dst (src :: existing) acc)
              acc refs)
          g Graph.empty;
    }

  let orphan_tables (fk : t) (rfk : t) =
    let fk = fk.graph in
    let rfk = rfk.graph in
    let all = Graph.fold (fun k _ acc -> k :: acc) fk [] in
    List.filter
      (fun t ->
        (not (Graph.mem t fk))
        || Graph.find t fk = []
           && ((not (Graph.mem t rfk)) || Graph.find t rfk = []))
      all

  let is_junction_table g table =
    match Graph.find_opt table g with
    | Some refs -> List.length refs = 2
    | None -> false

  let reference_heavy rfk threshold =
    Graph.fold
      (fun table refs acc ->
        if List.length refs >= threshold then table :: acc else acc)
      rfk []

  let export_in_degree_of_graph rfk =
    Graph.fold (fun table refs acc -> (table, List.length refs) :: acc) rfk []

  let derive_data (schema : SchemaData.t) : DerivedData.t =
    let table_graph = schema.table_graph.graph in
    let fk : FkGraph.t =
      {
        graph =
          Graph.map
            (fun t ->
              List.map
                (fun fk -> (fk : ForeignKey.t).references_table)
                (t : Table.t).foreign_keys)
            table_graph;
      }
    in

    let rfk = build_rfk fk in
    let orphan_tables = orphan_tables fk rfk in

    let junction_tables =
      Graph.fold
        (fun t _ acc -> if is_junction_table fk.graph t then t :: acc else acc)
        fk.graph []
    in

    let reference_heavy = reference_heavy rfk.graph 2 in

    let in_degree = export_in_degree_of_graph rfk.graph in

    { fk; rfk; in_degree; orphan_tables; junction_tables; reference_heavy }
end
