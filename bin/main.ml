let main () = Dbrefs.Cli.run ()
let () = if !Sys.interactive then () else exit (main ())
