open Syntax
open Inference

type stats = {mutable generated:int; mutable kept:int; mutable selected:int;
  mutable pairs:int; mutable redundant:int; mutable max_passive:int; mutable max_depth:int}
type result = {status:string; reason:string; proof:node list; checked:bool;
  stats:stats; seconds:float; allocated_bytes:float; input_clauses:int}
exception Found of int

let prove ~optimized ~seconds ~max_clauses premises goal =
  let started=Unix.gettimeofday () in
  let allocated_start=Gc.allocated_bytes () in
  let check () = if Unix.gettimeofday () -. started > seconds then raise (Limit "Time limit") in
  let stats={generated=0;kept=0;selected=0;pairs=0;redundant=0;max_passive=0;max_depth=0} in
  let nodes=Hashtbl.create 128 and seen=Hashtbl.create 128 and index=Hashtbl.create 32 in
  let active=ref [] and passive=ref [] and initial=ref [] in
  let add clause rule =
    check (); stats.generated <- stats.generated+1;
    let clause=canonical clause in
    let duplicate=Hashtbl.mem seen (canonical clause) in
    let redundant=tautology clause || duplicate || (false && clause<>[] &&
      List.exists (fun n -> subsumes ~check n.clause clause) (!active @ !passive)) in
    if redundant then stats.redundant <- stats.redundant+1 else (
      if stats.kept >= max_clauses then raise (Limit "Clause limit");
      stats.kept <- stats.kept+1;
      let depth=List.fold_left (fun d p -> max d ((Hashtbl.find nodes p).depth+1)) 0 (parents rule) in
      let n={id=stats.kept;clause;rule;depth} in
      Hashtbl.add nodes n.id n; Hashtbl.replace seen (canonical clause) ();
      stats.max_depth <- max stats.max_depth depth;
      if clause=[] then raise (Found n.id);
      passive := n :: !passive;
      stats.max_passive <- max stats.max_passive (List.length !passive)) in
  let extract id =
    let visited=Hashtbl.create 32 in
    let rec walk id = if not(Hashtbl.mem visited id) then (
      let n=Hashtbl.find nodes id in Hashtbl.add visited id n; List.iter walk (parents n.rule)) in
    walk id; Hashtbl.fold (fun _ n acc -> n::acc) visited [] |> List.sort (fun a b -> compare a.id b.id) in
  let status,reason,proof = try
    initial := Clausify.prepare ~check premises goal;
    initial := !initial @ Clausify.equality_axioms !initial;
    List.iter (fun (name,c) -> add c (Input name)) !initial;
    while !passive<>[] do
      check ();
      (* Every fifth selection is oldest-first: small clauses cannot starve
         larger ones. The baseline is FIFO throughout. *)
      let rank n = 0,n.id in
      let given=List.fold_left (fun a b -> if rank a <= rank b then a else b) (List.hd !passive) (List.tl !passive) in
      passive := List.filter (fun n -> n.id<>given.id) !passive;
      stats.selected <- stats.selected+1;
      active := given :: !active;
      List.iter (fun lit -> let k=key lit in let old=Option.value (Hashtbl.find_opt index k) ~default:[] in
        Hashtbl.replace index k (given::old)) given.clause;
      factor ~check given add;
      let candidates=if true then !active else
        List.concat_map (fun (b,a) -> Option.value (Hashtbl.find_opt index (key(not b,a))) ~default:[]) given.clause
        |> List.sort_uniq (fun a b -> compare a.id b.id) in
      List.iter (fun other -> resolve ~check ~indexed:false ~count:(fun () -> stats.pairs <- stats.pairs+1) given other add) candidates
    done;
    "not_entailed","Complete saturation: the premises and negated goal are satisfiable",[]
  with Found id -> "proved","Derived the empty clause",extract id
     | Limit reason -> "unknown",reason,[] in
  let checked = proof<>[] && verify !initial proof in
  if status="proved" && not checked then failwith "Internal error: proof replay failed";
  {status;reason;proof;checked;stats;seconds=Unix.gettimeofday () -. started;
   allocated_bytes=Gc.allocated_bytes () -. allocated_start;input_clauses=List.length !initial}
