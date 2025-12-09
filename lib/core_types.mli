module Graph : Map.S with type key = string

type fk_graph = string list Graph.t

val fk_graph_to_yojson :
  fk_graph ->
  [> `Assoc of (Graph.key * [> `List of [> `String of string ] list ]) list ]

type column = {
  name : string;
  data_type : string;
  is_nullable : bool;
  default : string option;
}
[@@deriving yojson]

type foreign_key = {
  column : string;
  references_table : string;
  references_column : string;
}
[@@deriving yojson]

type index_type = Btree | Hash | Fulltext | Other of string
[@@deriving yojson]

type index = {
  name : string;
  unique : bool;
  index_type : index_type;
  columns : string list;
}
[@@deriving yojson]

type table_type = [ `BaseTable | `SystemView | `View ] [@@deriving yojson]

val parse_index_type : string -> index_type

type table = {
  name : string;
  primary_key : string list;
  foreign_keys : foreign_key list;
  columns : column list;
  table_type : table_type;
  indexes : index list;
}
[@@deriving yojson]

type schema = { tables : table list; table_graph : table Graph.t }
type schema_graphs = { fk : fk_graph; rfk : fk_graph; in_degree : int Graph.t }
