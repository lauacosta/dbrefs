type t =
  | Invalid_DSN of string
  | Unsupported_driver of string
  | Execution_error of string
  | Dsn_scheme_error of string
[@@deriving show, yojson]
