module M = Mariadb.Blocking
module Graph = Core_types.Graph

val spawn_connection :
  ?host:string -> ?user:string -> ?pass:string -> unit -> M.t

val key_column_usage : string -> string list Graph.t
val build_schema : string -> Core_types.schema
