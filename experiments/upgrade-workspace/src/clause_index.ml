open Syntax
open Inference

(* Sign/predicate/arity is a necessary matching condition. The index only
   filters candidates; rigid one-way matching remains the final decision. *)
type t = { buckets: ((bool * string * int), node list) Hashtbl.t;
           anchors: ((bool * string * int), node list) Hashtbl.t }
let create () = {buckets=Hashtbl.create 64;anchors=Hashtbl.create 64}
let keys n = uniq(List.map key n.clause)
let get t k = Option.value (Hashtbl.find_opt t.buckets k) ~default:[]
let add t n =
  let ks=keys n in
  List.iter (fun k -> Hashtbl.replace t.buckets k (n::get t k)) ks;
  match ks with [] -> () | k::_ -> Hashtbl.replace t.anchors k
    (n::Option.value (Hashtbl.find_opt t.anchors k) ~default:[])
let remove t n =
  let ks=keys n in
  List.iter (fun k -> Hashtbl.replace t.buckets k
    (List.filter (fun old -> old.id<>n.id) (get t k))) ks;
  match ks with [] -> () | k::_ -> Hashtbl.replace t.anchors k
    (List.filter (fun old -> old.id<>n.id) (Option.value (Hashtbl.find_opt t.anchors k) ~default:[]))
let unique = List.sort_uniq (fun a b -> compare a.id b.id)
let forward t c = List.concat_map (fun k ->
  Option.value (Hashtbl.find_opt t.anchors k) ~default:[]) (uniq(List.map key c))
let backward t c = match c with
  | [] -> []
  | _ -> List.map (fun l -> get t (key l)) c
      |> List.fold_left (fun best ns -> match best with None -> Some ns
          | Some old -> Some(if List.length ns < List.length old then ns else old)) None
      |> Option.value ~default:[]
let possible a b =
  List.length a.clause <= List.length b.clause &&
  List.for_all (fun k -> List.mem k (keys b)) (keys a)
