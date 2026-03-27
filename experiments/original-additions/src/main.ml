open Syntax
open Inference
open Prover

let str s =
  let b=Buffer.create 32 in Buffer.add_char b '"';
  String.iter (fun c -> match c with
    | '"' -> Buffer.add_string b "\\\"" | '\\' -> Buffer.add_string b "\\\\"
    | c when Char.code c < 32 -> Buffer.add_string b (Printf.sprintf "\\u%04x" (Char.code c))
    | c -> Buffer.add_char b c) s;
  Buffer.add_char b '"'; Buffer.contents b
let obj xs = "{" ^ String.concat "," (List.map (fun (k,v) -> str k ^ ":" ^ v) xs) ^ "}"
let arr f xs = "[" ^ String.concat "," (List.map f xs) ^ "]"
let num = string_of_int
let subst s = obj (List.map (fun (x,t) -> x,str(term_string t)) s)
let node_json n =
  let rule,source,pivots,s = match n.rule with
    | Input label -> "input",label,[],[]
    | Resolve(_,_,i,j,s) -> "resolution","",[i;j],s
    | Factor(_,i,j,s) -> "factoring","",[i;j],s in
  obj ["id",num n.id;"clause",str(clause_string n.clause);"rule",str rule;
       "source",str source;"parents",arr num (parents n.rule);"pivots",arr num pivots;
       "substitution",subst s;"depth",num n.depth]
let output mode r =
  let s=r.stats in obj ["status",str r.status;"reason",str r.reason;"mode",str mode;
    "proof_checked",string_of_bool r.checked;"proof",arr node_json r.proof;
    "metrics",obj ["elapsed_ms",Printf.sprintf "%.4f" (r.seconds*.1000.);
      "ocaml_peak_heap_bytes",num r.heap_bytes;"input_clauses",num r.input_clauses;
      "generated_clauses",num s.generated;"kept_clauses",num s.kept;
      "selected_clauses",num s.selected;"literal_pair_checks",num s.pairs;
      "redundant_clauses",num s.redundant;"max_passive",num s.max_passive;
      "max_derivation_depth",num s.max_depth;"proof_steps",num(List.length r.proof)]]

let () =
  let baseline=ref false and seconds=ref 3.0 and cap=ref 5000 and path=ref None in
  Arg.parse ["--baseline",Arg.Set baseline," FIFO without indexing or subsumption";
    "--seconds",Arg.Set_float seconds," Maximum search seconds";
    "--max-clauses",Arg.Set_int cap," Maximum retained clauses"]
    (fun p -> path:=Some p) "qed [options] [problem.qed]; default input is stdin";
  try
    if not(Float.is_finite !seconds) || !seconds <= 0. || !cap < 1 then failwith "Limits must be positive";
    let ic=match !path with None -> stdin | Some p -> open_in p in
    let rec read acc = match input_line ic with line -> read (String.trim line::acc) | exception End_of_file -> List.rev acc in
    let lines=read [] |> List.filter (fun s -> s<>"" && s.[0]<>'#') in
    if !path<>None then close_in ic;
    let rec split acc = function
      | "---"::rest -> List.rev acc,rest
      | x::xs -> split (x::acc) xs
      | [] -> failwith "Separate premises from the goal with a line containing ---" in
    let premises,goals=split [] lines in
    let goal=match goals with [g] -> Parser.parse g | _ -> failwith "Expected exactly one goal after ---" in
    let premises=List.mapi (fun i p -> "premise_" ^ string_of_int(i+1),Parser.parse p) premises in
    let r=prove ~optimized:(not !baseline) ~seconds:!seconds ~max_clauses:!cap premises goal in
    print_endline(output (if !baseline then "baseline" else "optimized") r)
  with
  | Failure msg | Sys_error msg -> print_endline(obj["status",str "error";"reason",str msg]); exit 2
  | Stack_overflow -> print_endline(obj["status",str "unknown";"reason",str "Expression nesting limit"])
