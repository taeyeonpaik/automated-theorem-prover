open Syntax
open Inference
let checks=ref 0
let test name b = incr checks; if not b then (prerr_endline ("FAIL: " ^ name); exit 1)
let fails f = try ignore(f ()); false with Unify | Failure _ -> true
let p s = Parser.parse s
let solve ?(optimized=true) ps g = Prover.prove ~optimized ~seconds:2. ~max_clauses:3000
  (List.mapi (fun i s -> "p" ^ string_of_int i,p s) ps) (p g)
let () =
  test "occurs check" (fails (fun () -> unify [Var "x",Fn("f",[Var "x"])]));
  test "indirect occurs check" (fails (fun () -> unify [Var "x",Var "y";Var "y",Fn("f",[Var "x"])]));
  let s=unify [Var "x",Fn("f",[Var "y"]);Var "y",Fn("a",[])] in
  test "substitution composition" (apply s (Var "x")=Fn("f",[Fn("a",[])]));
  test "arity mismatch" (fails(fun () -> unify_atoms ("p",[]) ("p",[Var "x"])));
  let a=true,("p",[Var "x"]) and b=true,("p",[Fn("a",[])]) in
  test "one-way subsumption" (subsumes ~check:(fun () -> ()) [a] [b]);
  test "rigid target variables" (not(subsumes ~check:(fun () -> ()) [b] [a]));
  test "factoring not pruned by its parent" (not(subsumes ~check:(fun () -> ()) [a;true,("p",[Var "y"])] [a]));
  test "unifiable opposites are not a tautology" (not(tautology [a;false,("p",[Fn("a",[])])]));
  test "exact opposites are a tautology" (tautology [a;false,snd a]);
  test "quantifier scope" (p "forall x. p(x) -> q(x)"=Forall("x",Imp(Atom("p",[Var "x"]),Atom("q",[Var "x"]))));
  test "malformed input" (fails(fun () -> p "forall x p(x)"));
  test "arithmetic not silently evaluated" (fails(fun () -> p "2 + 2 = 4"));
  let cases = [
    "Socrates",["forall x. human(x) -> mortal(x)";"human(socrates)"],"mortal(socrates)","proved";
    "factoring",["forall x y. p(x) | p(y)";"forall x y. ~p(x) | ~p(y)"],"false","proved";
    "existential witness",["exists x. p(x)";"forall x. p(x) -> q(x)"],"exists x. q(x)","proved";
    "distinct witnesses",["exists x. p(x)";"exists x. q(x)"],"exists x. p(x) & q(x)","not_entailed";
    "variable shadowing",["forall x. p(x) & (exists x. q(x))"],"forall x. p(x)","proved";
    "shadowed existential",["exists x. p(x) & (forall x. q(x))"],"exists x. p(x) & q(x)","proved";
    "fresh variable collision",["forall V1. p(V1)"],"p(a)","proved";
    "fresh Skolem collision",["exists x. p(x)";"~p(sk1)";"~p(sk2)"],"false","not_entailed";
    "free goal universally closed",["p(a)"],"p(X)","not_entailed";
    "universal premise",["p(X)"],"p(a)","proved";
    "nonempty domain",[],"(forall x. p(x)) -> exists x. p(x)","proved";
    "quantifier order",[],"(forall x. exists y. r(x,y)) -> (exists y. forall x. r(x,y))","not_entailed";
    "functions",["forall x. p(x) -> p(f(x))";"p(a)"],"p(f(f(a)))","proved";
    "reflexivity",[],"forall x. x = x","proved";
    "equality substitution",["a = b";"p(a)"],"p(b)","proved";
    "function congruence",["a = b"],"f(a) = f(b)","proved";
    "separate symbol namespaces",["a = b";"f(a)";"f(a) = c"],"f(b)","proved";
    "symmetry",["a = b"],"b = a","proved";
    "transitivity",["a = b";"b = c"],"a = c","proved";
    "inconsistent premises",["p";"~p"],"q","proved";
    "affirming consequent",["p -> q";"q"],"p","not_entailed";
    "excluded middle",[],"p | ~p","proved";
    "biconditional",["p <-> q";"p"],"q","proved";
    "true goal",[],"true","proved";
    "false goal",[],"false","not_entailed";
    "TPTP quantifiers",["! [X] : (human(X) => mortal(X))";"human(socrates)"],"mortal(socrates)","proved"
  ] in
  List.iter (fun (name,ps,g,expected) -> List.iter (fun optimized ->
    let r=solve ~optimized ps g in
    let bounded_equality = not optimized && List.mem name ["equality substitution";"function congruence";"transitivity";"separate symbol namespaces"] in
    test (name ^ (if optimized then " optimized" else " baseline") ^ " got " ^ r.status)
      (r.status=expected || (bounded_equality && r.status="unknown"));
    if r.status="proved" then test (name ^ " replay") r.checked) [true;false]) cases;
  let r=solve ["p"] "p" in
  let inputs=Clausify.prepare ~check:(fun () -> ()) ["p0",p "p"] (p "p") in
  test "valid certificate" (verify inputs r.proof);
  let bad=List.map (fun n -> if n.clause=[] then {n with clause=[true,("forged",[])]} else n) r.proof in
  test "reject corrupted conclusion" (not(verify inputs bad));
  let bad=List.map (fun n -> match n.rule with Resolve(a,b,_,j,s) -> {n with rule=Resolve(a,b,99,j,s)} | _ -> n) r.proof in
  test "reject corrupted pivot" (not(verify inputs bad));
  let bad=List.map (fun n -> match n.rule with Input _ -> {n with rule=Input "forged"} | _ -> n) r.proof in
  test "reject invented axiom" (not(verify inputs bad));
  let r=Prover.prove ~optimized:true ~seconds:1. ~max_clauses:1 ["p",p "p"] (p "q") in
  test "limit is unknown" (r.status="unknown");
  Printf.printf "%d OCaml checks passed.\n" !checks
