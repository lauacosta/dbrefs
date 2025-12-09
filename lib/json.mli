module Graph = Core_types.Graph

type fk_graph = Core_types.fk_graph

module Json_export : sig
  val yojson_of_graph :
    fk_graph ->
    [> `Assoc of (string * [> `List of [> `String of string ] list ]) list ]

  val yojson_of_in_degree :
    'a list Graph.t -> [> `Assoc of (string * [> `Int of int ]) list ]

  val export :
    fk:fk_graph ->
    rfk:fk_graph ->
    orphans:string list ->
    junctions:string list ->
    reference_heavy:string list ->
    [> `Assoc of
       (string
       * [> `Assoc of
            (string * [> `Int of int | `List of [> `String of string ] list ])
            list
         | `List of [> `String of string ] list ])
       list ]
end
