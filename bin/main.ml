open Dbdoc.Json
open Dbdoc.Analyzer

let () =
  let fk =
    Graph.empty
    |> Graph.add "orders" [ "users"; "products" ]
    |> Graph.add "user_roles" [ "users"; "roles" ]
    |> Graph.add "payments" [ "orders" ]
    |> Graph.add "categories" [] |> Graph.add "logs" []
  in

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

  Yojson.Safe.pretty_to_channel stdout json
