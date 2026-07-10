open Syntax
exception Unify

let rec occurs x = function Var y -> x=y | Fn(_,ts) -> List.exists (occurs x) ts
let unify pairs =
  let rec go s = function
    | [] -> List.map (fun (x,t) -> x,apply s t) s
    | (a,b)::rest ->
      let a=apply s a and b=apply s b in
      if a=b then go s rest else match a,b with
      | Var x,t | t,Var x -> if occurs x t then raise Unify; go ((x,t)::s) rest
      | Fn(f,ts),Fn(g,us) when f=g && List.length ts=List.length us -> go s (List.combine ts us @ rest)
      | _ -> raise Unify in go [] pairs
let unify_atoms (p,ts) (q,us) =
  if p<>q || List.length ts<>List.length us then raise Unify;
  unify (List.combine ts us)
let without i xs = List.filteri (fun j _ -> i<>j) xs

let rec term_match s a b =
    match a,b with
    | Var x,t -> (match List.assoc_opt x s with None -> (x,t)::s | Some u when u=t -> s | _ -> raise Unify)
    | Fn(f,ts),Fn(g,us) when f=g && List.length ts=List.length us -> List.fold_left2 term_match s ts us
    | _ -> raise Unify

(* One-way matching: target variables are rigid, never instantiated. *)
let subsumes ~check c d =
  let c=rename "s:" c and d=rename "t:" d in
  let rec search s targets = function
    | [] -> true
    | (b,(p,ts))::rest -> List.exists (fun (j,(e,(q,us))) ->
        check ();
        if b<>e || p<>q || List.length ts<>List.length us then false else
        try search (List.fold_left2 term_match s ts us) (without j targets) rest with Unify -> false)
        (List.mapi (fun j t -> j,t) targets) in
  List.length c <= List.length d && search [] d c

type rule = Input of string
  | Resolve of int * int * int * int * substitution
  | Factor of int * int * int * substitution
  | EqResolve of int * int * substitution
  | Paramod of int * int * int * int * int * int list * substitution
type node = {id:int; clause:clause; rule:rule; depth:int}
let parents = function Input _ -> [] | Resolve(a,b,_,_,_) -> [a;b] | Factor(a,_,_,_) | EqResolve(a,_,_) -> [a]
  | Paramod(a,b,_,_,_,_,_) -> [a;b]

let resolve ~check ~indexed ~count a b emit =
  let left=rename "l:" a.clause and right=rename "r:" b.clause in
  List.iteri (fun i (sign,atom) -> List.iteri (fun j (other,atom2) ->
    check ();
    let complementary = sign<>other && key(sign,atom)=key(not other,atom2) in
    if not indexed || complementary then (
      count ();
      if complementary then try
        let s=unify_atoms atom atom2 in
        emit (normalize(instantiate s (without i left @ without j right))) (Resolve(a.id,b.id,i,j,s))
      with Unify -> ())) right) left

let factor ~check a emit =
  List.iteri (fun i (sign,atom) -> List.iteri (fun j (other,atom2) ->
    check ();
    if i<j && sign=other then try
      let s=unify_atoms atom atom2 in
      emit (normalize(instantiate s (without j a.clause))) (Factor(a.id,i,j,s))
    with Unify -> ()) a.clause) a.clause

(* These generators use full paramodulation in both directions. Ordering is
   used for terminating simplification, never to prune the complete calculus. *)
let equality_resolve ~check a emit =
  List.iteri (fun i -> function
    | false,("=",[l;r]) -> check (); (try let s=unify [l,r] in
        emit (normalize(instantiate s (without i a.clause))) (EqResolve(a.id,i,s)) with Unify -> ())
    | _ -> ()) a.clause

let paramodulate ~check ~count a b emit =
  let left=rename "l:" a.clause and right=rename "r:" b.clause in
  List.iteri (fun i -> function
    | true,("=",[l;r]) when l<>r ->
      List.iteri (fun side (lhs,rhs) ->
        List.iteri (fun j (sign,atom) -> List.iter (fun (path,t) ->
          check (); count ();
          try let s=unify [lhs,t] in
            let changed=List.mapi (fun k lit -> if k=j then sign,Equality.replace_atom atom path rhs else lit) right in
            emit (normalize(instantiate s (without i left @ changed))) (Paramod(a.id,b.id,i,side,j,path,s))
          with Unify -> ()) (Equality.atom_positions atom)) right) [l,r;r,l]
    | _ -> ()) left

(* Destructive simplification requires MATCHING: never instantiate a target
   variable just to shorten its clause. Each replacement retains a certificate. *)
let simplify_once ?(rewrite=true) ~check units n =
  let right=rename "r:" n.clause in
  let rec try_units = function
    | [] -> None
    | u::us when u.id=n.id -> try_units us
    | u::us ->
      let attempt () = match rename "l:" u.clause with
        | [sign,atom] ->
          let rec literals j = function
            | [] -> raise Unify
            | (other,at)::rest -> check ();
              if sign<>other && key(sign,atom)=key(not other,at) then
                (try let s=term_match [] (Fn(fst atom,snd atom)) (Fn(fst at,snd at)) in
                  normalize(instantiate s (without j right)),Resolve(u.id,n.id,0,j,s)
                with Unify -> literals (j+1) rest)
              else literals (j+1) rest in
          (try literals 0 right with Unify -> match sign,atom with
            | true,("=",[l;r]) when rewrite ->
              let side,lhs,rhs = if Equality.greater l r then 0,l,r
                else if Equality.greater r l then 1,r,l else raise Unify in
              let rec literals j = function
                | [] -> raise Unify
                | (b,at)::rest ->
                  let rec places = function
                    | [] -> literals (j+1) rest
                    | (path,t)::more -> check ();
                      (try let s=term_match [] lhs t in
                        let changed=List.mapi (fun k lit -> if k=j then b,Equality.replace_atom at path rhs else lit) right in
                        normalize(instantiate s changed),Paramod(u.id,n.id,0,side,j,path,s)
                       with Unify -> places more) in
                  places(Equality.atom_positions at) in literals 0 right
            | _ -> raise Unify)
        | _ -> raise Unify in
      (try Some(attempt ()) with Unify -> try_units us) in
  let rec reflex i = function
    | [] -> try_units units
    | (false,("=",[l;r]))::_ when l=r -> Some(without i n.clause,EqResolve(n.id,i,[]))
    | _::rest -> reflex (i+1) rest in
  reflex 0 n.clause

(* Replay recorded substitutions without calling the search or unifier.
   Parsing, clausification and the equality axioms remain trusted. *)
let verify inputs proof =
  let checked=Hashtbl.create 32 in
  let get id = (Hashtbl.find checked id).clause in
  let valid_subst s =
    List.length (uniq(List.map fst s))=List.length s &&
    let domain=List.map fst s in List.for_all (fun (_,t) -> not(List.exists (fun x -> List.mem x domain) (vars t))) s in
  let step n =
    let expected = match n.rule with
    | Input label -> List.assoc label inputs
    | Resolve(a,b,i,j,s) ->
      if not(valid_subst s) then raise Unify;
      let left=instantiate s (rename "l:" (get a)) and right=instantiate s (rename "r:" (get b)) in
      let x,at=List.nth left i and y,bt=List.nth right j in
      if x=y || at<>bt then raise Unify;
      normalize(without i left @ without j right)
    | EqResolve(a,i,s) ->
      if not(valid_subst s) then raise Unify;
      let c=instantiate s (get a) in
      (match List.nth c i with false,("=",[l;r]) when l=r -> normalize(without i c) | _ -> raise Unify)
    | Paramod(a,b,i,side,j,path,s) ->
      if not(valid_subst s) || path=[] || (side<>0 && side<>1) then raise Unify;
      let left=instantiate s (rename "l:" (get a)) and right=instantiate s (rename "r:" (get b)) in
      let l,r=match List.nth left i with true,("=",[l;r]) -> if side=0 then l,r else r,l | _ -> raise Unify in
      let sign,atom=List.nth right j in
      if Equality.atom_at atom path<>l then raise Unify;
      let changed=List.mapi (fun k lit -> if k=j then sign,Equality.replace_atom atom path r else lit) right in
      normalize(without i left @ changed)
    | Factor(a,i,j,s) ->
      if not(valid_subst s) || i=j then raise Unify;
      let c=instantiate s (get a) in
      if List.nth c i <> List.nth c j then raise Unify;
      normalize(without j c) in
    if Hashtbl.mem checked n.id || canonical expected<>n.clause then raise Unify;
    Hashtbl.add checked n.id n in
  try List.iter step proof;
    match List.rev proof with last::_ -> last.clause=[] | [] -> false
  with Unify | Not_found | Failure _ | Invalid_argument _ -> false
