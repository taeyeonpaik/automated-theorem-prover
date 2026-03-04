open Syntax
let () =
 let cs=Clausify.prepare ~check:(fun () -> ()) ["p",Parser.parse "forall V1. p(V1)"] (Parser.parse "p(a)") in
 assert(List.length cs=2);
 assert(Parser.parse "forall x. p(x) -> q(x)" = Forall("x",Imp(Atom("p",[Var "x"]),Atom("q",[Var "x"]))));
 print_endline "Scope and freshness checks passed."
