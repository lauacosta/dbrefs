run dsn="mariadb://root:secret@127.0.0.1:3306/tnoa":
    dune exec bin/main.exe {{dsn}}

test watch:
    dune runtest {{watch}}
