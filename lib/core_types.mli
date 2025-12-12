module Graph : Map.S with type key = string

val result_all : ('a, 'e) result list -> ('a list, 'e) result

module Column : sig
  type t = {
    name : string;
    data_type : string;
    is_nullable : bool;
    default : string option;
  }
end

module ForeignKey : sig
  type t = {
    column : string;
    references_table : string;
    references_column : string;
  }
end

module Index : sig
  type index_type = Btree | Hash | Fulltext | Other of string

  val parse_index_type : string -> index_type

  type t = {
    name : string;
    unique : bool;
    index_type : index_type;
    columns : string list;
  }
end

module Table : sig
  type table_type = SystemView | View | BaseTable | Unknown
  type engine = InnoDB | Aria | MyISAM | Unknown

  val get_table_type : string -> table_type
  val get_engine : string -> engine

  type t = {
    name : string;
    primary_key : string list;
    foreign_keys : ForeignKey.t list;
    columns : Column.t list;
    table_type : table_type;
    indexes : Index.t list;
    engine : engine;
  }
end

module TableGraph : sig
  type t = { graph : Table.t Graph.t }

  val to_yojson : t -> Yojson.Safe.t
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

module FkGraph : sig
  type t = { graph : string list Graph.t }

  val to_yojson : t -> Yojson.Safe.t
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

module SchemaData : sig
  type t = { tables : Table.t list; table_graph : TableGraph.t }

  val to_yojson : t -> Yojson.Safe.t
  val of_yojson : Yojson.Safe.t -> t Ppx_deriving_yojson_runtime.error_or
  (* val _ : Yojson.Safe.t -> t Ppx_deriving_yojson_runtime.error_or *)
end

module DerivedData : sig
  type t = {
    fk : FkGraph.t;
    rfk : FkGraph.t;
    in_degree : (string * int) list;
    orphan_tables : string list;
    junction_tables : string list;
    reference_heavy : string list;
  }

  val to_yojson : t -> Yojson.Safe.t
  val of_yojson : Yojson.Safe.t -> t Ppx_deriving_yojson_runtime.error_or
end

module Payload : sig
  type t = { schema_data : SchemaData.t; derived_data : DerivedData.t }

  val to_yojson : t -> Yojson.Safe.t
  val of_yojson : Yojson.Safe.t -> t Ppx_deriving_yojson_runtime.error_or
end
