(* QED's small first-order language. Constants are zero-argument functions. *)
type term = Var of string | Fn of string * term list
type atom = string * term list
type formula = True | False | Atom of atom | Not of formula
  | And of formula * formula | Or of formula * formula
  | Imp of formula * formula | Iff of formula * formula
  | Forall of string * formula | Exists of string * formula
type literal = bool * atom
type clause = literal list
type substitution = (string * term) list

let uniq xs = List.sort_uniq compare xs
let rec term_string = function
  | Var x -> x
  | Fn (f, []) -> f
  | Fn (f, ts) -> f ^ "(" ^ String.concat ", " (List.map term_string ts) ^ ")"
let atom_string = function
  | "=", [a;b] -> term_string a ^ " = " ^ term_string b
  | p, ts -> term_string (Fn (p,ts))
let literal_string (sign,a) = (if sign then "" else "~") ^ atom_string a
let clause_string = function
  | [] -> "[]"
  | c -> String.concat " | " (List.map literal_string c)
let rec vars = function Var x -> [x] | Fn (_,ts) -> uniq (List.concat_map vars ts)
let rec free = function
  | True | False -> []
  | Atom (_,ts) -> uniq (List.concat_map vars ts)
  | Not p -> free p
  | And(p,q) | Or(p,q) | Imp(p,q) | Iff(p,q) -> uniq (free p @ free q)
  | Forall(x,p) | Exists(x,p) -> List.filter ((<>) x) (free p)
let close p = List.fold_right (fun x q -> Forall(x,q)) (free p) p
let rec apply s = function
  | Var x as t -> (match List.assoc_opt x s with None -> t | Some u -> apply s u)
  | Fn(f,ts) -> Fn(f,List.map (apply s) ts)
let map_literal f (b,(p,ts)) = b,(p,List.map f ts)
let instantiate s c = List.map (map_literal (apply s)) c
let rename prefix c = List.map (map_literal (fun t ->
  let rec go = function Var x -> Var(prefix ^ x) | Fn(f,ts) -> Fn(f,List.map go ts) in go t)) c
let normalize c = uniq c
let tautology c = List.exists (fun (b,a) -> List.mem (not b,a) c) c
let key (b,(p,ts)) = b,p,List.length ts
let rec term_weight = function Var _ -> 1 | Fn(_,ts) -> 2 + List.fold_left (fun n t -> n + term_weight t) 0 ts
let weight c = List.fold_left (fun n (_,(_,ts)) -> n + 2 + List.fold_left (fun n t -> n + term_weight t) 0 ts) 0 c

(* A stable cheap alpha key. It may miss permuted variants, but never conflates
   inequivalent clauses. Full subsumption handles many remaining variants. *)
let canonical c =
  let names = Hashtbl.create 8 in
  let rec go = function
    | Var x -> let v = match Hashtbl.find_opt names x with
        | Some v -> v | None -> let v = "V" ^ string_of_int (Hashtbl.length names) in Hashtbl.add names x v; v in Var v
    | Fn(f,ts) -> Fn(f,List.map go ts) in
  normalize (List.map (map_literal go) (normalize c))

exception Limit of string
let validate formulas =
  let fs = Hashtbl.create 16 and ps = Hashtbl.create 16 in
  let add tbl name n = match Hashtbl.find_opt tbl name with
    | Some m when n <> m -> failwith ("Inconsistent arity for " ^ name)
    | _ -> Hashtbl.replace tbl name n in
  let rec term = function Var _ -> () | Fn(f,ts) -> add fs f (List.length ts); List.iter term ts in
  let rec form = function
    | Atom(p,ts) -> add ps p (List.length ts); List.iter term ts
    | Not p | Forall(_,p) | Exists(_,p) -> form p
    | And(p,q) | Or(p,q) | Imp(p,q) | Iff(p,q) -> form p; form q
    | True | False -> () in
  List.iter form formulas; fs,ps
