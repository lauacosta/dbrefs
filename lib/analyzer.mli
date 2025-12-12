module Analyzer : sig
  type t = Core_types.FkGraph.t

  val derive_data : Core_types.SchemaData.t -> Core_types.DerivedData.t
end
