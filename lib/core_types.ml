module Graph = Map.Make (String)
open Result.Syntax

let result_all (lst : ('a, 'e) result list) : ('a list, 'e) result =
  let rec aux acc = function
    | [] -> Ok (List.rev acc)
    | Ok x :: xs -> aux (x :: acc) xs
    | Error e :: _ -> Error e
  in
  aux [] lst

module Column = struct
  type t = {
    name : string;
    data_type : string;
    is_nullable : bool;
    default : string option;
  }
  [@@deriving yojson]
end

module ForeignKey = struct
  type t = {
    column : string;
    references_table : string;
    references_column : string;
  }
  [@@deriving yojson]
end

module Index = struct
  type index_type = Btree | Hash | Fulltext | Other of string
  [@@deriving yojson]

  let parse_index_type = function
    | "BTREE" -> Btree
    | "HASH" -> Hash
    | "FULLTEXT" -> Fulltext
    | s -> Other s

  type t = {
    name : string;
    unique : bool;
    index_type : index_type;
    columns : string list;
  }
  [@@deriving yojson]
end

module Table = struct
  type table_type = SystemView | View | BaseTable | Unknown
  [@@deriving yojson]
  (** https://mariadb.com/docs/server/server-usage/storage-engines *)
  type engine = InnoDB | Aria | MyISAM | Unknown
  [@@deriving yojson]

  let get_table_type s=             match s with
              | "BASE TABLE" -> BaseTable
              | "VIEW" -> View
              | "SYSTEM VIEW" -> SystemView
              | _ -> Unknown

  let get_engine s =             match s with
              | "InnoDB" -> InnoDB
              | "Aria" -> Aria
              | "MyISAM" -> MyISAM
              | _ -> Unknown

  type t = {
    name : string;
    primary_key : string list;
    foreign_keys : ForeignKey.t list;
    columns : Column.t list;
    table_type : table_type;
    indexes : Index.t list;
    engine: engine;
  }
  [@@deriving yojson]
end

module TableGraph = struct
  type t = { graph : Table.t Graph.t }

  let to_yojson (t : t) : Yojson.Safe.t =
    `Assoc
      (Graph.fold (fun k v acc -> (k, Table.to_yojson v) :: acc) t.graph [])

  let of_yojson (json : Yojson.Safe.t) : (t, string) result =
    match json with
    | `Assoc lst ->
        List.fold_left
          (fun acc (k, v_json) ->
            let* map = acc in
            let* v = Table.of_yojson v_json in
            Ok (Graph.add k v map))
          (Ok Graph.empty) lst
        |> Result.map (fun g -> { graph = g })
    | _ -> Error "Expected JSON object for TableGraph"
end

module FkGraph = struct
  type t = { graph : string list Graph.t }

  let to_yojson (t : t) : Yojson.Safe.t =
    `Assoc
      (Graph.fold
         (fun k v acc -> (k, `List (List.map (fun s -> `String s) v)) :: acc)
         t.graph [])

  let of_yojson (json : Yojson.Safe.t) : (t, string) result =
    match json with
    | `Assoc lst ->
        List.fold_left
          (fun acc (k, v_json) ->
            let* map = acc in
            match v_json with
            | `List vs ->
                let vs_str =
                  List.map
                    (function
                      | `String s -> Ok s | _ -> Error "Expected string")
                    vs
                in
                let* vs_ok = result_all vs_str in
                Ok (Graph.add k vs_ok map)
            | _ -> Error "Expected list for fk_graph values")
          (Ok Graph.empty) lst
        |> Result.map (fun g -> { graph = g })
    | _ -> Error "Expected JSON object for fk_graph"
end

module SchemaData = struct
  type t = {
    tables : Table.t list;
    table_graph : TableGraph.t;
        [@yojson
          { to_yojson = TableGraph.to_yojson; of_yojson = TableGraph.of_yojson }]
  }
  [@@deriving yojson]
end

module DerivedData = struct
  type t = {
    fk : FkGraph.t;
        [@yojson
          { to_yojson = FkGraph.to_yojson; of_yojson = FkGraph.of_yojson }]
    rfk : FkGraph.t;
        [@yojson
          { to_yojson = FkGraph.to_yojson; of_yojson = FkGraph.of_yojson }]
    in_degree : (string * int) list;
    orphan_tables : string list;
    junction_tables : string list;
    reference_heavy : string list;
  }
  [@@deriving yojson]
end

module Payload = struct
  type t = { schema_data : SchemaData.t; derived_data : DerivedData.t }
  [@@deriving yojson]
end
