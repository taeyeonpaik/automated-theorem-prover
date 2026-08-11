open Syntax
open Inference

type stats = {mutable generated:int; mutable kept:int; mutable selected:int;
  mutable pairs:int; mutable redundant:int; mutable max_passive:int; mutable max_depth:int;
  mutable subsumption_checks:int; mutable simplified:int; mutable backward:int; mutable paramodulations:int}
type result = {status:string; reason:string; proof:node list; checked:bool;
  stats:stats; seconds:float; allocated_bytes:float; input_clauses:int}
exception Found of int

let legacy ~optimized ~seconds ~max_clauses premises goal =
  let started=Unix.gettimeofday () in
  let allocated_start=Gc.allocated_bytes () in
  let check () = if Unix.gettimeofday () -. started > seconds then raise (Limit "Time limit") in
  let stats={generated=0;kept=0;selected=0;pairs=0;redundant=0;max_passive=0;max_depth=0;subsumption_checks=0;simplified=0;backward=0;paramodulations=0} in
  let nodes=Hashtbl.create 128 and seen=Hashtbl.create 128 and index=Hashtbl.create 32 in
  let active=ref [] and passive=ref [] and initial=ref [] in
  let add clause rule =
    check (); stats.generated <- stats.generated+1;
    let clause=canonical clause in
    let duplicate=Hashtbl.mem seen (canonical clause) in
    let redundant=tautology clause || duplicate || (optimized && clause<>[] &&
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
      let rank n = if optimized && stats.selected mod 5 <> 0 then weight n.clause,n.id else 0,n.id in
      let given=List.fold_left (fun a b -> if rank a <= rank b then a else b) (List.hd !passive) (List.tl !passive) in
      passive := List.filter (fun n -> n.id<>given.id) !passive;
      stats.selected <- stats.selected+1;
      active := given :: !active;
      List.iter (fun lit -> let k=key lit in let old=Option.value (Hashtbl.find_opt index k) ~default:[] in
        Hashtbl.replace index k (given::old)) given.clause;
      factor ~check given add;
      let candidates=if not optimized then !active else
        List.concat_map (fun (b,a) -> Option.value (Hashtbl.find_opt index (key(not b,a))) ~default:[]) given.clause
        |> List.sort_uniq (fun a b -> compare a.id b.id) in
      List.iter (fun other -> resolve ~check ~indexed:optimized ~count:(fun () -> stats.pairs <- stats.pairs+1) given other add) candidates
    done;
    "not_entailed","Complete saturation: the premises and negated goal are satisfiable",[]
  with Found id -> "proved","Derived the empty clause",extract id
     | Limit reason -> "unknown",reason,[] in
  let checked = proof<>[] && verify !initial proof in
  if status="proved" && not checked then failwith "Internal error: proof replay failed";
  {status;reason;proof;checked;stats;seconds=Unix.gettimeofday () -. started;
   allocated_bytes=Gc.allocated_bytes () -. allocated_start;input_clauses=List.length !initial}

(* Switches support controlled ablations without changing the old baseline. *)
type features = {simplify:bool; indexing:bool; definitions:bool; equality:bool}
let all_features = {simplify=true;indexing=true;definitions=true;equality=true}

let improved features ~seconds ~max_clauses premises goal =
  let started=Unix.gettimeofday () and allocated_start=Gc.allocated_bytes () in
  let check () = if Unix.gettimeofday () -. started > seconds then raise (Limit "Time limit") in
  let stats={generated=0;kept=0;selected=0;pairs=0;redundant=0;max_passive=0;max_depth=0;
             subsumption_checks=0;simplified=0;backward=0;paramodulations=0} in
  let nodes=Hashtbl.create 128 and live=Hashtbl.create 128 and seen=Hashtbl.create 128 in
  let stored=Clause_index.create () and active_index=Clause_index.create () in
  let active=ref [] and passive=ref [] and units=ref [] and initial=ref [] in
  let pending=Queue.create () in
  let alive n=Hashtbl.mem live n.id in
  let all_live ()=Hashtbl.fold (fun _ n ns -> n::ns) live [] in
  let remove n = if alive n then (
    Hashtbl.remove live n.id; Clause_index.remove stored n; Clause_index.remove active_index n;
    active:=List.filter (fun m -> m.id<>n.id) !active;
    passive:=List.filter (fun m -> m.id<>n.id) !passive;
    units:=List.filter (fun m -> m.id<>n.id) !units) in
  let archive clause rule =
    check ();
    if stats.kept>=max_clauses then raise (Limit "Clause limit");
    stats.kept<-stats.kept+1;
    let depth=List.fold_left (fun d id -> max d ((Hashtbl.find nodes id).depth+1)) 0 (parents rule) in
    let n={id=stats.kept;clause=canonical clause;rule;depth} in
    Hashtbl.add nodes n.id n; stats.max_depth<-max stats.max_depth depth;
    if n.clause=[] then raise(Found n.id); n in
  let taut c = tautology c || List.exists (function true,("=",[l;r]) -> l=r | _ -> false) c in
  let unit_candidates n = List.filter (fun u ->
    match u.clause with
    | [true,("=",_)] when features.equality -> true
    | [b,a] -> List.exists (fun (s,at) -> key(not b,a)=key(s,at)) n.clause
    | _ -> false) !units in
  let rec simplified n =
    if not features.simplify then n else
    match simplify_once ~rewrite:features.equality ~check (unit_candidates n) n with
    | None -> n
    | Some(c,r) -> stats.simplified<-stats.simplified+1; simplified(archive c r) in
  let subsumes a b =
    check ();
    if not(Clause_index.possible a b) then false else (
      stats.subsumption_checks<-stats.subsumption_checks+1;
      subsumes ~check a.clause b.clause) in
  let add clause rule =
    check (); stats.generated<-stats.generated+1;
    let c=canonical clause in
    if taut c || Hashtbl.mem seen c then stats.redundant<-stats.redundant+1 else (
      let n=simplified(archive c rule) in
      let candidates=if features.indexing then Clause_index.forward stored n.clause else all_live () in
      if taut n.clause || Hashtbl.mem seen n.clause || List.exists (fun old -> subsumes old n) candidates
      then stats.redundant<-stats.redundant+1 else (
        if features.simplify then (
          let targets=if features.indexing then Clause_index.backward stored n.clause else all_live () in
          List.iter (fun old -> if subsumes n old then (
            remove old; stats.backward<-stats.backward+1)) targets);
        Hashtbl.add live n.id n; Hashtbl.replace seen n.clause (); Clause_index.add stored n;
        passive:=n::!passive;
        stats.max_passive<-max stats.max_passive (List.length !passive);
        if List.length n.clause=1 then (
          units:=n::!units;
          if features.simplify then (
            let b,a=List.hd n.clause in
            let targets=if features.equality && fst a="=" && b then all_live ()
              else Clause_index.get stored (key(not b,a)) in
            List.iter (fun old -> if old.id<>n.id && alive old then
              match simplify_once ~rewrite:features.equality ~check [n] old with
              | None -> ()
              | Some(c,r) -> remove old; stats.simplified<-stats.simplified+1; Queue.add (c,r) pending) targets)))) in
  let drain ()=while not(Queue.is_empty pending) do let c,r=Queue.take pending in add c r done in
  let extract id =
    let visited=Hashtbl.create 32 in
    let rec walk id=if not(Hashtbl.mem visited id) then (
      let n=Hashtbl.find nodes id in Hashtbl.add visited id n; List.iter walk (parents n.rule)) in
    walk id; Hashtbl.fold (fun _ n ns -> n::ns) visited [] |> List.sort (fun a b -> compare a.id b.id) in
  let status,reason,proof = try
    initial:=Clausify.prepare ~definitional:features.definitions ~check premises goal;
    if not features.equality then initial:=!initial @ Clausify.equality_axioms !initial;
    List.iter (fun (label,c) -> add c (Input label); drain ()) !initial;
    while !passive<>[] || not(Queue.is_empty pending) do
      check (); drain ();
      if !passive<>[] then (
        let rank n=if stats.selected mod 5=0 then 0,n.id else weight n.clause,n.id in
        let given=List.fold_left (fun a b -> if rank a<=rank b then a else b) (List.hd !passive) (List.tl !passive) in
        passive:=List.filter (fun n -> n.id<>given.id) !passive;
        active:=given::!active; Clause_index.add active_index given;
        stats.selected<-stats.selected+1;
        factor ~check given add;
        if features.equality then equality_resolve ~check given add;
        let candidates=List.concat_map (fun (b,a) -> Clause_index.get active_index (key(not b,a))) given.clause
          |> Clause_index.unique in
        List.iter (fun other -> if alive given && alive other then
          resolve ~check ~indexed:true ~count:(fun () -> stats.pairs<-stats.pairs+1) given other add) candidates;
        if features.equality && alive given then (
          let eqs n=List.exists (function true,("=",[l;r]) -> l<>r | _ -> false) n.clause in
          let targets=if eqs given then !active else Clause_index.get active_index (true,"=",2) in
          List.iter (fun other -> if alive given && alive other then (
            let count ()=stats.paramodulations<-stats.paramodulations+1 in
            if eqs given then paramodulate ~check ~count given other add;
            if other.id<>given.id && eqs other then paramodulate ~check ~count other given add)) targets))
    done;
    "not_entailed","Complete saturation: the premises and negated goal are satisfiable",[]
  with Found id -> "proved","Derived the empty clause",extract id
     | Limit reason -> "unknown",reason,[] in
  let checked=proof<>[] && verify !initial proof in
  if status="proved" && not checked then failwith "Internal error: proof replay failed";
  {status;reason;proof;checked;stats;seconds=Unix.gettimeofday ()-.started;
   allocated_bytes=Gc.allocated_bytes ()-.allocated_start;input_clauses=List.length !initial}

let prove ?(features=all_features) ~optimized ~seconds ~max_clauses premises goal =
  if optimized then improved features ~seconds ~max_clauses premises goal
  else legacy ~optimized:false ~seconds ~max_clauses premises goal
