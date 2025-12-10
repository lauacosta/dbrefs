module Analyzer : sig
  type t = Core_types.fk_graph

  val in_degree : 'a list Core_types.Graph.t -> string -> int
  val build_rfk : t -> t
  val orphan_tables : t -> t -> string list
  val is_junction_table : 'a list Core_types.Graph.t -> string -> bool
  val reference_heavy : 'a list Core_types.Graph.t -> int -> string list
end
