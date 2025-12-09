let or_die where = function
  | Ok r -> r
  | Error (i, e) -> failwith @@ Printf.sprintf "%s: (%d) %s" where i e

(** Type signature needed to implement an adapter for a database *)
module type DBAdapter = sig
  type t

  val spawn_connection :
    ?host:string -> ?user:string -> ?pass:string -> unit -> t

  val build_schema : string -> Core_types.schema
end

module Backend (B : DBAdapter) = struct
  type t = B.t

  let spawn_connection = B.spawn_connection
  let build_schema = B.build_schema
end
