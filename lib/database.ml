let or_die where = function
  | Ok r -> r
  | Error (i, e) -> failwith @@ Printf.sprintf "%s: (%d) %s" where i e

(** Type signature needed to implement an adapter for a database *)
module type DBAdapter = sig
  type t

  val build_schema : Dsn.DSN.t -> Core_types.schema
end

module Backend (B : DBAdapter) = struct
  type t = B.t

  let build_schema = B.build_schema
end
