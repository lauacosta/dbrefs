(* module StringSet : Set.S with type elt = string *)
(* module Graph = Core_types.Graph *)

(* module M : sig *)
(*   module Inner = Mariadb.Blocking *)
(*   module Stmt = Mariadb.Blocking.Stmt *)

(*   type stmt = Stmt.t *)
(*   type conn = Inner.t *)

(*   val with_conn : Inner.t -> (Inner.t -> 'a) -> 'a *)
(*   val with_stmt : Inner.t -> string -> (Inner.Stmt.t -> 'a) -> 'a *)
(*   val stream : Inner.Res.t -> Inner.Row.Map.t Seq.t *)
(* end *)

(* module MariadbBackend : Database.DBAdapter *)

(* module MariadbDB : sig *)
(*   type t = MariadbBackend.t *)

(*   val build_schema : conn:MariadbBackend.t -> string -> Core_types.schema *)
(* end *)

module M : sig
  module Inner = Mariadb.Blocking
  module Stmt = Mariadb.Blocking.Stmt

  type stmt = Inner.Stmt.t
  type conn = Inner.t

  val with_conn : Inner.t -> (Inner.t -> 'a) -> 'a
  val with_stmt : Inner.t -> string -> (Inner.Stmt.t -> 'a) -> 'a
  val stream : Inner.Res.t -> Inner.Row.Map.t Seq.t
end

module MariadbBackend : Database.DBAdapter

module MariadbDB : sig
  type t = MariadbBackend.t

  val build_schema : Dsn.DSN.t -> Core_types.schema
end
