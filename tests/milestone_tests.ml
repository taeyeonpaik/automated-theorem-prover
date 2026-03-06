open Syntax
open Inference
let () =
 assert(try ignore(unify [Var "x",Fn("f",[Var "x"])]);false with Unify -> true);
 let s=unify [Var "x",Fn("a",[])] in assert(apply s (Var "x")=Fn("a",[]));
 print_endline "Unification checks passed."
