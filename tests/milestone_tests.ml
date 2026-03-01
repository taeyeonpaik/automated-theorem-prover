open Syntax
let () = assert (Clausify.prepare ~check:(fun () -> ()) ["p",Parser.parse "p"] (Parser.parse "p") <> []); print_endline "Clausification check passed."
