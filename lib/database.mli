val or_die : string -> ('a, int * string) result -> 'a

module type DBAdapter = sig
  type t

  val build_schema : Dsn.DSN.t -> Core_types.schema
end

module Backend : (B : DBAdapter) -> sig
  type t = B.t

  val build_schema : Dsn.DSN.t -> Core_types.schema
end
