module Graph = Core_types.Graph

module Analyzer = struct
  type t = Core_types.fk_graph

  let in_degree g table_name =
    match Graph.find_opt table_name g with
    | None -> 0
    | Some src -> List.length src

  let build_rfk (g : t) : t =
    Graph.fold
      (fun src refs acc ->
        List.fold_left
          (fun acc dst ->
            let existing =
              match Graph.find_opt dst acc with Some l -> l | None -> []
            in
            Graph.add dst (src :: existing) acc)
          acc refs)
      g Graph.empty

  let orphan_tables (fk : t) (rfk : t) =
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
end
