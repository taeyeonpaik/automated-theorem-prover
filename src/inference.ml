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

(* One-way matching: target variables are rigid, never instantiated. *)
let subsumes ~check c d =
  let c=rename "s:" c and d=rename "t:" d in
  let rec term_match s a b =
    match a,b with
    | Var x,t -> (match List.assoc_opt x s with None -> (x,t)::s | Some u when u=t -> s | _ -> raise Unify)
    | Fn(f,ts),Fn(g,us) when f=g && List.length ts=List.length us -> List.fold_left2 term_match s ts us
    | _ -> raise Unify in
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
type node = {id:int; clause:clause; rule:rule; depth:int}
let parents = function Input _ -> [] | Resolve(a,b,_,_,_) -> [a;b] | Factor(a,_,_,_) -> [a]

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

