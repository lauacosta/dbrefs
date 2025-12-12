module Graph = Core_types.Graph
module Dsn = Database.Dsn
module E = Errors

module StringSet : sig
  type elt = String.t
  type t = Set.Make(String).t

  val empty : t
  val add : elt -> t -> t
  val singleton : elt -> t
  val remove : elt -> t -> t
  val union : t -> t -> t
  val inter : t -> t -> t
  val disjoint : t -> t -> bool
  val diff : t -> t -> t
  val cardinal : t -> int
  val elements : t -> elt list
  val min_elt : t -> elt
  val min_elt_opt : t -> elt option
  val max_elt : t -> elt
  val max_elt_opt : t -> elt option
  val choose : t -> elt
  val choose_opt : t -> elt option
  val find : elt -> t -> elt
  val find_opt : elt -> t -> elt option
  val find_first : (elt -> bool) -> t -> elt
  val find_first_opt : (elt -> bool) -> t -> elt option
  val find_last : (elt -> bool) -> t -> elt
  val find_last_opt : (elt -> bool) -> t -> elt option
  val iter : (elt -> unit) -> t -> unit
  val fold : (elt -> 'acc -> 'acc) -> t -> 'acc -> 'acc
  val map : (elt -> elt) -> t -> t
  val filter : (elt -> bool) -> t -> t
  val filter_map : (elt -> elt option) -> t -> t
  val partition : (elt -> bool) -> t -> t * t
  val split : elt -> t -> t * bool * t
  val is_empty : t -> bool
  val mem : elt -> t -> bool
  val equal : t -> t -> bool
  val compare : t -> t -> int
  val subset : t -> t -> bool
  val for_all : (elt -> bool) -> t -> bool
  val exists : (elt -> bool) -> t -> bool
  val to_list : t -> elt list
  val of_list : elt list -> t
  val to_seq_from : elt -> t -> elt Seq.t
  val to_seq : t -> elt Seq.t
  val to_rev_seq : t -> elt Seq.t
  val add_seq : elt Seq.t -> t -> t
  val of_seq : elt Seq.t -> t
end

module M : sig
  module Inner = Mariadb.Blocking
  module Stmt = Mariadb.Blocking.Stmt

  type stmt = Inner.Stmt.t
  type conn = Inner.t

  val execute :
    Stmt.t ->
    Mariadb.Blocking.Field.value array ->
    (Mariadb.Blocking.Res.t, E.t) result

  val connect : Dsn.server -> (Inner.t, E.t) result
  val with_conn : Inner.t -> (Inner.t -> 'a) -> 'a
  val with_stmt : Inner.t -> string -> (Inner.Stmt.t -> 'a) -> 'a
  val stream : Inner.Res.t -> Inner.Row.Map.t Seq.t
end

type t = M.conn
type error = E.t

val spawn_connection : Dsn.t -> (M.Inner.t * string, E.t) result
val find_opt : ('a, 'b option) Hashtbl.t -> 'a -> 'b option

val get_string :
  M.Inner.Field.t M.Inner.Row.StringMap.t ->
  M.Inner.Row.StringMap.key ->
  string ->
  string

val get_bool :
  M.Inner.Field.t M.Inner.Row.StringMap.t ->
  M.Inner.Row.StringMap.key ->
  bool ->
  bool

val get_string_opt :
  M.Inner.Field.t M.Inner.Row.StringMap.t ->
  M.Inner.Row.StringMap.key ->
  string option

val query_map :
  M.Inner.t ->
  string ->
  query:string ->
  row_to_kv:(M.Inner.Row.Map.t -> 'a * 'b) ->
  merge:('c option -> 'b -> 'c option) ->
  (('a, 'c option) Hashtbl.t, E.t) result

val create_column_map :
  M.Inner.t ->
  string ->
  ( (string, (Core_types.Column.t list * StringSet.t) option) Hashtbl.t,
    E.t )
  result

val create_table_rows :
  M.Inner.t ->
  string ->
  ( (string * Core_types.Table.table_type * Core_types.Table.engine) list,
    E.t )
  result

val create_fk_map :
  M.Inner.t ->
  string ->
  ( (string, (Core_types.ForeignKey.t list * StringSet.t) option) Hashtbl.t,
    E.t )
  result

val create_index_map :
  M.Inner.t ->
  string ->
  ( ( string,
      (string, bool * Core_types.Index.index_type * string list) Hashtbl.t )
    Hashtbl.t,
    E.t )
  result

val build_schema : Dsn.t -> (Core_types.SchemaData.t, E.t) result
