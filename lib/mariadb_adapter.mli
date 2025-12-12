module Dsn = Database.Dsn

module M : sig
  module Inner = Mariadb.Blocking
  module Stmt = Mariadb.Blocking.Stmt

  type stmt = Inner.Stmt.t
  type conn = Inner.t

  val with_conn : Inner.t -> (Inner.t -> 'a) -> 'a
  val with_stmt : Inner.t -> string -> (Stmt.t -> 'a) -> 'a
  val stream : Inner.Res.t -> Inner.Row.Map.t Seq.t
end

module MariadbBackend : Database.DBAdapter

module MariadbDB : sig
  type t = MariadbBackend.t
  type error = Errors.t

  val build_schema : Dsn.t -> (Core_types.SchemaData.t, error) result
end
