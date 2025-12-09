module Graph = Map.Make (String)

type fk_graph = string list Graph.t

module RFK = struct
  type t = fk_graph

  (* let in_degree g table_name = *)
  (*   match Graph.find_opt table_name g with *)
  (*   | None -> 0 *)
  (*   | Some src -> List.length src *)

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

let () =
  let fk =
    Graph.empty
    |> Graph.add "orders" [ "users"; "products" ]
    |> Graph.add "user_roles" [ "users"; "roles" ]
    |> Graph.add "payments" [ "orders" ]
    |> Graph.add "categories" [] |> Graph.add "logs" []
  in

  let rfk = RFK.build_rfk fk in

  let orphans = RFK.orphan_tables fk rfk in

  let junctions =
    Graph.fold
      (fun t _ acc -> if RFK.is_junction_table fk t then t :: acc else acc)
      fk []
  in

  let heavy = RFK.reference_heavy rfk 2 in

  let json =
    Json_export.export ~fk ~rfk ~orphans ~junctions ~reference_heavy:heavy
  in

  Yojson.Safe.pretty_to_channel stdout json
