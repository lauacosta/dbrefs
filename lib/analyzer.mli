module Graph = Core_types.Graph

module Analyzer : sig
  type t = Core_types.fk_graph

  val in_degree : 'a list Graph.t -> Graph.key -> int
  val build_rfk : t -> t
  val orphan_tables : t -> t -> Graph.key list
  val is_junction_table : 'a list Graph.t -> Graph.key -> bool
  val reference_heavy : 'a list Graph.t -> int -> Graph.key list
end
