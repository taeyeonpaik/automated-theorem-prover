open Syntax

(* Refutation pipeline: NNF, fresh bound variables, Skolemization, CNF.
   Skolemization preserves satisfiability, not logical equivalence. *)
let prepare ?(definitional=false) ~check premises goal =
  let formulas = List.map (fun (name,p) -> name,close p) premises @ ["negated_goal",Not(close goal)] in
  let symbols,predicates = validate (List.map snd formulas) in
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
    | Forall(x,p) -> let v=Var(fresh "#v") in skolem ((x,v)::env) (universals@[v]) p
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
  (* Fresh predicates carry every free variable of their subformula. Using
     propositional constants here would be unsound for first-order formulas. *)
  let defcnf formula =
    let clauses=ref [] and definitions=Hashtbl.create 32 in
    let emit c = check (); clauses := normalize c :: !clauses;
      if List.length !clauses > 10000 then raise (Limit "CNF expansion limit") in
    let neg (b,a) = not b,a in
    let rec literal = function
      | Atom a -> true,a | Not(Atom a) -> false,a
      | f -> match Hashtbl.find_opt definitions f with
        | Some lit -> lit
        | None ->
          let rec name () = let n=fresh "qed_def" in
            if Hashtbl.mem predicates n then name () else n in
          let n=name () and vs=free f in
          Hashtbl.add predicates n (List.length vs);
          let d=true,(n,List.map (fun x -> Var x) vs) in
          Hashtbl.add definitions f d;
          (match f with
           | True -> emit [d] | False -> emit [neg d]
           | And(p,q) -> let a=literal p and b=literal q in
               emit [neg d;a]; emit [neg d;b]; emit [d;neg a;neg b]
           | Or(p,q) -> let a=literal p and b=literal q in
               emit [neg d;a;b]; emit [d;neg a]; emit [d;neg b]
           | _ -> assert false); d in
    (* Preserve formulas already in clausal form; introduce definitions only
       below disjunctions, where distribution would otherwise duplicate work. *)
    let rec disj = function Or(p,q) -> disj p @ disj q | f -> [literal f] in
    let rec top = function
      | True -> () | False -> emit []
      | And(p,q) -> top p; top q
      | f -> emit(disj f) in
    top formula; List.rev !clauses in
  (* Tiny formulas are cheaper without auxiliary predicates. Count only up
     to the threshold; do not build the distributive product to estimate it. *)
  let rec estimate = function
    | True -> 0 | And(p,q) -> check (); min 33 (estimate p + estimate q)
    | Or(p,q) -> check (); min 33 (estimate p * estimate q)
    | _ -> 1 in
  let convert p = if definitional && estimate p > 32 then defcnf p else cnf p in
  List.concat_map (fun (label,p) ->
    let p=nnf true p in let p=skolem [] [] p in
    List.mapi (fun i c -> Printf.sprintf "%s:%d" label (i+1),normalize c) (convert p)) formulas

let equality_axioms clauses =
  let atoms=List.concat_map snd clauses in
  if not (List.exists (fun (_, (p,_)) -> p="=") atoms) then [] else
  let fs=Hashtbl.create 16 and ps=Hashtbl.create 16 in
  let rec collect = function Var _ -> () | Fn(f,ts) -> Hashtbl.replace fs f (List.length ts); List.iter collect ts in
  List.iter (fun (_, (p,ts)) -> Hashtbl.replace ps p (List.length ts); List.iter collect ts) atoms;
  let x=Var "X" and y=Var "Y" and z=Var "Z" in
  let eq a b = true,("=",[a;b]) and neq a b = false,("=",[a;b]) in
  let congruences table is_function =
    Hashtbl.fold (fun name n acc -> if n=0 || name="=" then acc else
      let xs=List.init n (fun i -> Var("X"^string_of_int i))
      and ys=List.init n (fun i -> Var("Y"^string_of_int i)) in
      let guards=List.map2 neq xs ys in
      let tail=if is_function then [eq (Fn(name,xs)) (Fn(name,ys))]
        else [false,(name,xs);true,(name,ys)] in
      ("equality:" ^ (if is_function then "function:" else "predicate:") ^ name,normalize(guards@tail))::acc) table [] |> List.sort compare in
  ["equality:reflexivity",[eq x x]; "equality:symmetry",normalize[neq x y;eq y x];
   "equality:transitivity",normalize[neq x y;neq y z;eq x z]]
  @ congruences fs true @ congruences ps false
