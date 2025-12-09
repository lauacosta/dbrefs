module Graph = Core_types.Graph

type fk_graph = Core_types.fk_graph
type exported_graph = (string * string list) list [@@deriving yojson]
type exported_in_degree = (string * int) list [@@deriving yojson]

type export = {
  fk_graph : exported_graph;
  rfk_graph : exported_graph;
  in_degree : exported_in_degree;
  orphan_tables : string list;
  junction_tables : string list;
  reference_heavy : string list;
}
[@@deriving yojson]

let export_graph g = Graph.bindings g

let export_in_degree_of_graph rfk =
  Graph.fold (fun table refs acc -> (table, List.length refs) :: acc) rfk []

let export ~(fk : fk_graph) ~(rfk : fk_graph) ~(orphans_tables : string list)
    ~(junction_tables : string list) ~(reference_heavy : string list) =
  {
    fk_graph = export_graph fk;
    rfk_graph = export_graph rfk;
    in_degree = export_in_degree_of_graph rfk;
    orphan_tables = orphans_tables;
    junction_tables;
    reference_heavy;
  }
