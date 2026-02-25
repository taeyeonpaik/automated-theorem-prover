open Syntax
let () = assert (Parser.parse "p -> p" = Imp(Atom("p",[]),Atom("p",[]))); print_endline "Parser check passed."
