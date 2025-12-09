module Graph : Map.S with type key = string

type fk_graph = string list Graph.t [@@deriving yojson]

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

type table = {
  name : string;
  columns : column list;
  primary_key : string list;
  foreign_keys : foreign_key list;
  indexes : index list;
}
[@@deriving yojson]

type schema = { tables : table list; table_map : table Graph.t }
[@@deriving yojson]

type schema_graphs = { fk : fk_graph; rfk : fk_graph; in_degree : int Graph.t }
[@@deriving yojson]
