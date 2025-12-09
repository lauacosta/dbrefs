module Graph : Map.S with type key = string

type fk_graph = string list Graph.t

module Analyzer : sig
  type t = fk_graph

  val build_rfk : t -> t
  val orphan_tables : t -> t -> String.t list
  val is_junction_table : 'a list Graph.t -> String.t -> bool
  val reference_heavy : 'a list Graph.t -> int -> String.t list
end
