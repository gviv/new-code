open Printf
open Lazy
module L = List
module S = String

(** File where the calt feature will be written. *)
let output_file = "calt.fea"

(** The ligatures are defined here. A ligature is the list of the glyphs that
    should merge. For example, the ligature ["hyphen"; "greater"] tells the font
    to replace `->' by a glyph named `hyphen_greater.liga'. The latter
    is assumed to exist in the font. *)
let ligas = [
  ["period"; "period"];
]

(** General list iterator. *)
let rec it_list f l a =
  match l with
  | [] -> a
  | e :: sl -> f e (it_list f sl a) sl

(** Generates the default `ignore sub' statements. *)
(* The purpose of these statements is described below. *)
let gen_default_ignores liga =
  (* Disable the ligature if it's followed by a glyph identical to the last of
    the ligature (disables the ligature if there are many in a row). *)
  let rule1 =
    match liga with
    | [] -> raise (Failure "rule1")
    | s :: l -> (s ^ "'") :: l @ [L.hd @@ L.rev l]
  (* Disable the ligature if it's preceded by a glyph identical to the first of
    the ligature (disables the last ligature of a "row of ligatures"). *)
  and rule2 =
    match liga with
    | [] -> raise (Failure "rule2")
    | s :: l -> s :: (s ^ "'") :: l in
  let rules = [S.concat " " rule1; S.concat " " rule2] in
  L.map (fun rule -> sprintf "%4signore sub %s;\n" "" rule) rules

(** Generates the default substitution targets that will be used when
    generating the default substitutions. *)
let gen_default_sub_targets liga =
  let gen_target quote_idx =
    let f s (res, i) l =
      let r = if quote_idx = i then (s ^ "'") :: l else "space" :: force res in
      (lazy r, i + 1) in
    force @@ fst @@ it_list f liga (lazy [], 0) in
  L.mapi (fun i _ -> S.concat " " (gen_target i)) liga

(** Generates the default substitutions that allow the cursor to be placed
    inside a ligature. *)
let gen_default_subs liga lookup_name =
  let gen_sub = sprintf "%4ssub %s by %s;\n" "" in
  match gen_default_sub_targets liga with
  | [] -> raise (Failure "gen_default_subs")
  | t :: l -> let f target = gen_sub target "space" in
      gen_sub t (lookup_name ^ ".liga") :: L.map f l

(** Generates the lookups. *)
let gen_lookups ligas =
  let gen_lookup liga =
    let lookup_name = S.concat "_" liga in
    let default_ignores = S.concat "" (gen_default_ignores liga)
    and default_subs = S.concat "" (gen_default_subs liga lookup_name) in
    sprintf "%2slookup %s {\n%s%2s} %s;" "" lookup_name
      (default_ignores ^ default_subs) "" lookup_name in
  L.map (fun liga -> gen_lookup liga) ligas

let main () =
  let oc = open_out output_file
  and ligas = L.sort (fun l1 l2 -> L.length l2 - L.length l1) ligas in
  let lookups = S.concat "\n\n" (gen_lookups ligas) in
  fprintf oc "feature calt {\n%s\n} calt;\n" lookups;
  close_out oc

let () = main ()
