val or_die : string -> ('a, int * string) result -> 'a

module type DBAdapter = sig
  type t

  val spawn_connection :
    ?host:string -> ?user:string -> ?pass:string -> unit -> t

  val build_schema : string -> Core_types.schema
end

module Backend : (B : DBAdapter) -> sig
  type t = B.t

  val spawn_connection :
    ?host:string -> ?user:string -> ?pass:string -> unit -> B.t

  val build_schema : string -> Core_types.schema
end
