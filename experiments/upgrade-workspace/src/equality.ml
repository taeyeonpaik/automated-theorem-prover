(* LPO adapted from John Harrison, copyright (c) 2003-2007.
   See docs/HARRISON-LICENSE.txt for redistribution terms. *)
open Syntax

(* Lexicographic path ordering, following Harrison's order.ml. Unlike a raw
   size comparison this ordering is stable under substitution and context. *)
let rec greater s t =
  match s,t with
  | _,Var x -> s<>t && List.mem x (vars s)
  | Fn(f,ss),Fn(g,ts) ->
      List.exists (fun u -> u=t || greater u t) ss ||
      (List.for_all (greater s) ts &&
       (if f=g then lex ss ts else compare (f,List.length ss) (g,List.length ts)>0))
  | _ -> false
and lex ss ts = match ss,ts with
  | s::ss,t::ts -> if s=t then lex ss ts else greater s t
  | _ -> false

let rec positions t = match t with
  | Var _ -> []
  | Fn(_,ts) -> ([],t)::List.concat(List.mapi (fun i u ->
      List.map (fun (path,v) -> i::path,v) (positions u)) ts)
let atom_positions (_,ts) = List.concat(List.mapi (fun i t ->
  List.map (fun (path,u) -> i::path,u) (positions t)) ts)
let rec at t = function
  | [] -> t
  | i::path -> (match t with Fn(_,ts) -> at (List.nth ts i) path | Var _ -> raise Not_found)
let rec replace t path value = match path,t with
  | [],_ -> value
  | i::rest,Fn(f,ts) ->
      if i<0 || i>=List.length ts then raise Not_found;
      Fn(f,List.mapi (fun j u -> if i=j then replace u rest value else u) ts)
  | _ -> raise Not_found
let atom_at (p,ts) path = at (Fn(p,ts)) path
let replace_atom (p,ts) path value = match replace (Fn(p,ts)) path value with
  | Fn(q,us) when p=q -> q,us | _ -> raise Not_found
