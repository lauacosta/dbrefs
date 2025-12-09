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

val export :
  fk:fk_graph ->
  rfk:fk_graph ->
  orphans_tables:string list ->
  junction_tables:string list ->
  reference_heavy:string list ->
  export
