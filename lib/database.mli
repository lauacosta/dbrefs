module M = Mariadb.Blocking

type table_type = [ `SystemView | `View | `BaseTable ] [@@deriving yojson]

type table_info = { table_name : string; table_type : table_type }
[@@deriving yojson]

val spawn_connection :
  ?host:string -> ?user:string -> ?pass:string -> unit -> M.t

val stream : M.Res.t -> M.Row.Map.t Seq.t
val key_column_usage : string -> string list Analyzer.Graph.t
val tables_information_schema : string -> table_info list
