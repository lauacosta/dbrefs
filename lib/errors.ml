type t =
  | Invalid_DSN of string
  | Unsupported_driver of string
  | Execution_error of string
  | Dsn_scheme_error of string
[@@deriving show, yojson]

let red s = "\027[31m" ^ s ^ "\027[0m"
let yellow s = "\027[33m" ^ s ^ "\027[0m"
let bold s = "\027[1m" ^ s ^ "\027[0m"

let pp_error (e : t) : string =
  match e with
  | Invalid_DSN msg ->
      Printf.sprintf "%s %s" (red (bold "Invalid DSN:")) (yellow msg)
  | Unsupported_driver driver ->
      Printf.sprintf "%s %s" (red (bold "Unsupported driver:")) (yellow driver)
  | Execution_error msg ->
      Printf.sprintf "%s %s" (red (bold "Execution error:")) (yellow msg)
  | Dsn_scheme_error msg ->
      Printf.sprintf "%s %s" (red (bold "DSN scheme error:")) (yellow msg)
