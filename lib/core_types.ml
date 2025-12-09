module Graph = Map.Make (String)

type fk_graph = string list Graph.t

let fk_graph_to_yojson (g : fk_graph) =
  `Assoc
    (Graph.fold
       (fun key refs acc ->
         (key, `List (List.map (fun r -> `String r) refs)) :: acc)
       g [])

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

(* TODO: Extend by reading the mariadb docs*)
type index_type = Btree | Hash | Fulltext | Other of string
[@@deriving yojson]

let parse_index_type = function
  | "BTREE" -> Btree
  | "HASH" -> Hash
  | "FULLTEXT" -> Fulltext
  | s -> Other s

type index = {
  name : string;
  unique : bool;
  index_type : index_type;
  columns : string list;
}
[@@deriving yojson]

type table_type = [ `SystemView | `View | `BaseTable ] [@@deriving yojson]

(* TODO: Extend with more data *)
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
