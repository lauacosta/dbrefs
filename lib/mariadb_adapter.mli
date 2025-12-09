module StringSet : Set.S with type elt = string
module M = Mariadb.Blocking
module Graph = Core_types.Graph
module MariadbBackend : Database.DBAdapter

module MariadbDB : sig
  type t = MariadbBackend.t

  val spawn_connection :
    ?host:string -> ?user:string -> ?pass:string -> unit -> MariadbBackend.t

  val build_schema : string -> Core_types.schema
end
