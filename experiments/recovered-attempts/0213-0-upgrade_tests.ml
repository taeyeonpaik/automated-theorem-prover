open Syntax
open Inference
let count=ref 0
let test name value=incr count; if not value then failwith name
let parse=Parser.parse
let solve ?(features=Prover.all_features) ps g = Prover.prove ~features ~optimized:true ~seconds:2. ~max_clauses:5000
  (List.mapi (fun i p -> string_of_int i,parse p) ps) (parse g)
let () =
  let cases=[
    ["~p(X) | q(X)";"p(a)";"p(b)";"~q(b)"],"false","proved";
    ["p(f(X))";"f(a) = a";"~p(f(b))"],"false","proved";
    ["p(a)";"~p(X) | q(X)";"~q(b)"],"false","not_entailed";
    ["f(X,Y) = f(Y,X)"],"f(a,b) = f(b,a)","proved";
    ["p | a = b";"~p";"r(f(a))"],"r(f(b))","proved";
    ["X = a"],"b = c","proved";
    ["a = b | a = c";"a != b"],"a = c","proved";
    ["f(f(X)) = f(X)";"forall x. exists y. f(y) = x"],"f(X) = X","proved";
    ["a != b";"f(a) = f(b)"],"false","not_entailed";
    ["p(X) | q(X)";"p(a)";"~p(b)";"~q(b)"],"false","proved";
    ["qed_def1(a)";"forall x. (p(x) & q(x)) | (r(x) & s(x))"],"qed_def1(b)","not_entailed";
    ["forall x. (p(x) & q(x)) | (r(x) & s(x))";"~p(a)";"~r(a)"],"false","proved"
  ] in
  List.iteri (fun i (ps,g,status) -> let r=solve ps g in
    test ("upgrade case "^string_of_int i^": "^r.status) (r.status=status);
    if status="proved" then test "replay" r.checked) cases;
  let vars=List.init 15 (fun i -> Printf.sprintf "(p%d & q%d)" i i) in
  let formula=String.concat " | " vars in
  let inputs=["big",parse formula] in
  let cs=Clausify.prepare ~definitional:true ~check:(fun () -> ()) inputs False in
  test "definitional CNF avoids 32768-way distribution" (List.length cs<100);
  test "old CNF expansion limit" (try ignore(Clausify.prepare ~check:(fun () -> ()) inputs False);false with Limit _ -> true);
  let pclauses=Clausify.prepare ~definitional:true ~check:(fun () -> ())
    ["f",parse "forall x. (p(x) & q(x)) | (r(x) & s(x))"] False in
  test "definitions retain first-order variables" (List.exists (fun (_,c) ->
    List.exists (fun (_, (p,ts)) -> String.starts_with ~prefix:"qed_def" p && ts<>[]) c) pclauses);
  let ps=["f(X,Y) = f(Y,X)"] and g="f(a,b) = f(b,a)" in
  let r=solve ps g in
  let initial=Clausify.prepare ~definitional:true ~check:(fun () -> ()) ["0",parse(List.hd ps)] (parse g) in
  test "paramodulation certificate present" (List.exists (fun n -> match n.rule with Paramod _ -> true | _ -> false) r.proof);
  let corrupt change=List.map (fun n -> {n with rule=change n.rule}) r.proof in
  test "reject corrupt paramodulation position" (not(verify initial (corrupt(function
    | Paramod(a,b,i,s,j,_,u) -> Paramod(a,b,i,s,j,[99],u) | r -> r))));
  test "reject corrupt direction" (not(verify initial (corrupt(function
    | Paramod(a,b,i,_,j,p,u) -> Paramod(a,b,i,2,j,p,u) | r -> r))));
  test "reject cyclic substitution" (not(verify initial (corrupt(function
    | Paramod(a,b,i,s,j,p,_) -> Paramod(a,b,i,s,j,p,["X",Var "X"]) | r -> r))));
  let reflex=solve [] "a = a" in
  let init=Clausify.prepare ~definitional:true ~check:(fun () -> ()) [] (parse "a = a") in
  test "reject bad equality-resolution pivot" (not(verify init (List.map(fun n -> match n.rule with
    | EqResolve(a,_,s) -> {n with rule=EqResolve(a,99,s)} | _ -> n) reflex.proof)));
  let a=Fn("a",[]) and b=Fn("b",[]) and x=Var "X" in
  test "LPO decreases proper subterms" (Equality.greater (Fn("f",[x])) x);
  test "LPO rejects unsafe variable introduction" (not(Equality.greater (Fn("f",[x;x;x])) (Fn("g",[x;Var "Y"]))));
  test "LPO ground orientation" (Equality.greater b a && not(Equality.greater a b));
  let n id c={id;clause=c;rule=Input(string_of_int id);depth=0} in
  let index=Clause_index.create () in
  let ns=[n 1 [true,("p",[x])];n 2 [false,("q",[])];n 3 [true,("p",[a]);true,("r",[])]] in
  List.iter (Clause_index.add index) ns;
  let target=n 9 [true,("p",[b]);false,("q",[])] in
  List.iter(fun old -> if subsumes ~check:(fun()->()) old.clause target.clause then
    test "forward index retains all matches" (List.exists(fun n->n.id=old.id)(Clause_index.forward index target.clause))) ns;
  Clause_index.remove index (List.hd ns);
  test "index deletes stale postings" (not(List.exists(fun n->n.id=1)(Clause_index.forward index target.clause)));
  List.iter (fun features -> let r=solve ~features ["p(a)";"p(X) -> q(X)"] "q(a)" in
    test "ablation remains sound" (r.status="proved" && r.checked))
    [{Prover.all_features with simplify=false};{Prover.all_features with indexing=false};
     {Prover.all_features with definitions=false};{Prover.all_features with equality=false}];
  Printf.printf "%d upgrade checks passed.\n" !count
