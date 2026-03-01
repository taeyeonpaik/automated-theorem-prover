open Syntax

(* Refutation pipeline: NNF, fresh bound variables, Skolemization, CNF.
   Skolemization preserves satisfiability, not logical equivalence. *)
let prepare ~check premises goal =
  let formulas = List.map (fun (name,p) -> name,close p) premises @ ["negated_goal",Not(close goal)] in
  let symbols,_ = validate (List.map snd formulas) in
  let serial = ref 0 in
  let fresh prefix = incr serial; prefix ^ string_of_int !serial in
  let rec nnf polarity f =
    check ();
    match f with
    | True -> if polarity then True else False
    | False -> if polarity then False else True
    | Atom _ -> if polarity then f else Not f
    | Not p -> nnf (not polarity) p
    | And(p,q) -> let a = nnf polarity p and b = nnf polarity q in if polarity then And(a,b) else Or(a,b)
    | Or(p,q) -> let a = nnf polarity p and b = nnf polarity q in if polarity then Or(a,b) else And(a,b)
    | Imp(p,q) -> nnf polarity (Or(Not p,q))
    | Iff(p,q) -> nnf polarity (And(Imp(p,q),Imp(q,p)))
    | Forall(x,p) -> if polarity then Forall(x,nnf true p) else Exists(x,nnf false p)
    | Exists(x,p) -> if polarity then Exists(x,nnf true p) else Forall(x,nnf false p) in
  let rec skolem env universals = function
    | Atom(p,ts) -> Atom(p,List.map (apply env) ts)
    | Not p -> Not(skolem env universals p)
    | And(p,q) -> let a=skolem env universals p in let b=skolem env universals q in And(a,b)
    | Or(p,q) -> let a=skolem env universals p in let b=skolem env universals q in Or(a,b)
    | Forall(x,p) -> let v=Var(fresh "V") in skolem ((x,v)::env) (universals@[v]) p
    | Exists(x,p) ->
      let rec name () = let s=fresh "sk" in if Hashtbl.mem symbols s then name () else s in
      let s=name () in Hashtbl.add symbols s (List.length universals);
      skolem ((x,Fn(s,universals))::env) universals p
    | True -> True | False -> False | _ -> assert false in
  let rec cnf = function
    | True -> [] | False -> [[]]
    | Atom a -> [[true,a]] | Not(Atom a) -> [[false,a]]
    | And(p,q) -> bounded (cnf p @ cnf q)
    | Or(p,q) ->
      let a=cnf p and b=cnf q in
      if List.length a * List.length b > 10000 then raise (Limit "CNF expansion limit");
      bounded (List.concat_map (fun c -> List.map (fun d -> check (); normalize(c@d)) b) a)
    | _ -> assert false
  and bounded cs = check (); if List.length cs > 10000 then raise (Limit "CNF expansion limit"); cs in
  List.concat_map (fun (label,p) ->
    let p=nnf true p in let p=skolem [] [] p in
    List.mapi (fun i c -> Printf.sprintf "%s:%d" label (i+1),normalize c) (cnf p)) formulas

