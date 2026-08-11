open Syntax

(* Recursive descent, with the same binding structure as Harrison's parser.
   Also accepts the logical operators of the untyped TPTP FOF/CNF subset. *)
let tokenize text =
  let n = String.length text in
  let word = function 'a'..'z'|'A'..'Z'|'0'..'9'|'_'|'$' -> true | _ -> false in
  let rec scan i acc =
    if i = n then List.rev acc else
    match text.[i] with
    | ' '|'\t'|'\n'|'\r' -> scan (i+1) acc
    | _ ->
      let op = List.find_opt (fun op -> let k = String.length op in i+k <= n && String.sub text i k = op)
        ["<=>";"<->";"==>";"=>";"->";"!=";"/\\";"\\/"] in
      match op with
      | Some op -> scan (i+String.length op) (op::acc)
      | None when word text.[i] ->
        let j = ref (i+1) in while !j < n && word text.[!j] do incr j done;
        scan !j (String.sub text i (!j-i)::acc)
      | None when String.contains "()[],.:~&|=!?" text.[i] -> scan (i+1) (String.make 1 text.[i]::acc)
      | None -> failwith (Printf.sprintf "Unexpected character %C at position %d" text.[i] (i+1))
  in scan 0 []

let parse text =
  let tokens = ref (tokenize text) in
  let peek () = match !tokens with t::_ -> t | [] -> "<end>" in
  let pop () = match !tokens with t::ts -> tokens := ts; t | [] -> failwith "Unexpected end of formula" in
  let accept ts = if List.mem (peek ()) ts then (ignore(pop ()); true) else false in
  let expect t = if not (accept [t]) then failwith ("Expected '" ^ t ^ "', found '" ^ peek () ^ "'") in
  let identifier () = let t = pop () in
    if t = "" || not (match t.[0] with 'a'..'z'|'A'..'Z'|'_'|'$' -> true | _ -> false)
      || List.mem t ["forall";"exists";"true";"false";"$true";"$false"]
    then failwith ("Expected an identifier, found '" ^ t ^ "'"); t in
  let rec term env =
    let name = identifier () in
    if accept ["("] then (
      if List.mem name env || (name.[0] >= 'A' && name.[0] <= 'Z') then failwith "A variable cannot be a function";
      Fn(name,args env))
    else if List.mem name env || (name.[0] >= 'A' && name.[0] <= 'Z') then Var name else Fn(name,[])
  and args env =
    if accept [")"] then [] else
    let t = term env in
    let rec rest acc = if accept [","] then rest (term env::acc) else (expect ")"; List.rev acc) in rest [t]
  and formula env =
    let p = implication env in
    if accept ["<=>";"<->"] then Iff(p,formula env) else p
  and implication env =
    let p = disjunction env in
    if accept ["=>";"->";"==>"] then Imp(p,implication env) else p
  and disjunction env =
    let rec rest p = if accept ["|";"\\/"] then rest (Or(p,conjunction env)) else p in rest (conjunction env)
  and conjunction env =
    let rec rest p = if accept ["&";"/\\"] then rest (And(p,unary env)) else p in rest (unary env)
  and unary env =
    if accept ["~"] then Not(unary env)
    else if List.mem (peek ()) ["forall";"exists";"!";"?"] then (
      let q = pop () in
      let bracket = accept ["["] in
      let rec names acc =
        let x = identifier () in
        if bracket then (if accept [","] then names (x::acc) else (expect "]"; expect ":"; List.rev (x::acc)))
        else if accept ["."] then List.rev (x::acc) else names (x::acc) in
      let xs = names [] in
      if List.length (uniq xs) <> List.length xs then failwith "Repeated variable in a quantifier";
      let body = if bracket then unary (xs@env) else formula (xs@env) in
      List.fold_right (fun x p -> if q="forall" || q="!" then Forall(x,p) else Exists(x,p)) xs body)
    else if accept ["("] then (let p = formula env in expect ")"; p)
    else if accept ["true";"$true"] then True
    else if accept ["false";"$false"] then False
    else (
      (* Predicate identifiers may be uppercase; variable convention applies
         only inside terms, or to the left of an equality. *)
      let name = identifier () in
      let ts = if accept ["("] then args env else [] in
      if List.mem (peek ()) ["=";"!="] then (
        let op = pop () in
        let lhs = if List.mem name env || (name.[0]>='A' && name.[0]<='Z') then
          (if ts <> [] then failwith "A variable cannot be a function"; Var name) else Fn(name,ts) in
        let a = Atom("=",[lhs;term env]) in if op="=" then a else Not a)
      else (if List.mem name env then failwith "A bound variable cannot be a predicate"; Atom(name,ts)))
  in
  if !tokens=[] then failwith "Please enter a formula";
  let p = formula [] in
  if !tokens<>[] then failwith ("Unexpected token '" ^ peek () ^ "'"); p
