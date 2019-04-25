open Printf
open Lazy
module L = List
module S = String

(** File where the features will be written. *)
let output_file = "features.fea"

(** Global glyph classes. The first component is the name of the class and the
    second is the glyphs to add to the class. *)
let classes : (string * string) list = []

(** A calt ligature is a ligature whose glyphs will merge into an ad hoc
    glyph. For example, the ligature ["hyphen"; "greater"] tells the font to
    replace `->' by a glyph named `hyphen_greater.liga'. The latter is assumed
    to exist in the font. *)
type calt_liga = string list

(** A kern ligature merely consists in shrinking the space between glyphs. *)
type kern_liga = {
  glyphs : string list; (** The glyphs to affect *)
  factor : int; (** The amount of shrinking desired *)
}

(** The calt ligatures to generate. *)
let calt_ligas : calt_liga list = [
  ["hyphen"; "greater"];
  ["less"; "hyphen"];
]

(** The kern ligatures to generate. *)
let kern_ligas : kern_liga list = [
  {glyphs = ["period"; "period"]; factor = 90};
  {glyphs = ["period"; "period"; "period"]; factor = 120};
  {glyphs = ["semicolon"; "semicolon"]; factor = 90};
  {glyphs = ["colon"; "colon"]; factor = 90};
  {glyphs = ["slash"; "slash"]; factor = 50};
  {glyphs = ["question"; "question"]; factor = 90};
  {glyphs = ["exclam"; "exclam"]; factor = 90};
]

(** Returns the `ignore' rules corresponding to the given glyphs. *)
let get_ignores : string list -> string list = function
  | _ -> []

(** General list iterator. *)
let rec it_list f l a =
  match l with
  | [] -> a
  | e :: sl -> f e (it_list f sl a) sl

(** Generates the glyph classes declarations. *)
let gen_classes classes =
  let f (name, glyphs) = sprintf "@%s = [%s];\n" name glyphs in
  S.concat "" (L.map f classes)

(** Generates the `ignore' statements. *)
let gen_ignores rule_type rules =
  let f rule = sprintf "%4signore %s %s;\n" "" rule_type rule in
  S.concat "" (L.map f rules)

(** Generates the default `ignore' statements. *)
(* The purpose of these statements is described below. *)
let gen_default_ignores glyphs rule_type =
  (* Disable the ligature if it's followed by a glyph identical to the last of
     the ligature (disables the ligature if there are many in a row). *)
  let rule1 =
    match glyphs with
    | [] -> raise (Failure "rule1")
    | s :: l -> (s ^ "'") :: l @ [L.hd @@ L.rev l]
  (* Disable the ligature if it's preceded by a glyph identical to the first of
     the ligature (disables the last ligature of a "row of ligatures"). *)
  and rule2 =
    match glyphs with
    | [] -> raise (Failure "rule2")
    | s :: l -> s :: (s ^ "'") :: l in
  gen_ignores rule_type [S.concat " " rule1; S.concat " " rule2]

(** Generates the substitution targets that will be used when generating the
    default substitutions. *)
let gen_sub_targets calt_liga =
  let gen_target quote_idx =
    let f s (res, i) l =
      let r = if quote_idx = i then (s ^ "'") :: l else "space" :: force res in
      (lazy r, i + 1) in
    force @@ fst @@ it_list f calt_liga (lazy [], 0) in
  L.mapi (fun i _ -> S.concat " " (gen_target i)) calt_liga

(** Generates the substitutions that allow the cursor to be placed inside a
    ligature. *)
let gen_subs calt_liga lookup_name =
  let gen_sub = sprintf "%4ssub %s by %s;\n" "" in
  match gen_sub_targets calt_liga with
  | [] -> raise (Failure "gen_subs")
  | t :: l -> let f target = gen_sub target "space" in
    gen_sub t (lookup_name ^ ".liga") :: L.map f l

(** Generic function to generate a lookup. *)
let gen_lookup_generic name content =
  sprintf "%2slookup %s {\n%s%2s} %s;" "" name content "" name

(** Generates the calt lookup corresponding to the given calt ligature. *)
let gen_calt_lookup calt_liga =
  let lookup_name = S.concat "_" calt_liga in
  let default_ignores = gen_default_ignores calt_liga "sub"
  and custom_ignores = gen_ignores "sub" (get_ignores calt_liga)
  and default_subs = S.concat "" (gen_subs calt_liga lookup_name) in
  let content = default_ignores ^ custom_ignores ^ default_subs in
  gen_lookup_generic lookup_name content

(** Generates the `pos' rule corresponding to the given kern ligature. *)
let gen_pos kern_liga =
  match kern_liga.glyphs with
  | [g1; g2] -> sprintf "%4spos %s' <%d 0 0 0> %s' <-%d 0 0 0>;\n" ""
                  g1 kern_liga.factor g2 kern_liga.factor
  | [g1; g2; g3] -> sprintf "%4spos %s' <%d 0 0 0> %s' 0 %s' <-%d 0 0 0>;\n" ""
                      g1 kern_liga.factor g2 g3 kern_liga.factor
  | _ -> raise (Failure "gen_pos: invalid glyphs")

(** Generates the kern lookup corresponding to the given kern ligature. *)
let gen_kern_lookup kern_liga =
  let lookup_name = S.concat "_" kern_liga.glyphs
  and default_ignores = gen_default_ignores kern_liga.glyphs "pos"
  and custom_ignores = gen_ignores "pos" (get_ignores kern_liga.glyphs) in
  let content = default_ignores ^ custom_ignores ^ gen_pos kern_liga in
  gen_lookup_generic lookup_name content

let main () =
  let oc = open_out output_file
  (* Sort the ligatures in descending order of their length *)
  and calt_ligas = L.sort (fun l1 l2 -> L.length l2 - L.length l1) calt_ligas
  and kern_ligas = L.sort
      (fun kl1 kl2 -> L.length kl2.glyphs - L.length kl1.glyphs) kern_ligas in
  let calt_lookups = S.concat "\n\n" (L.map gen_calt_lookup calt_ligas)
  and kern_lookups = S.concat "\n\n" (L.map gen_kern_lookup kern_ligas) in
  fprintf oc "%s\n" (gen_classes classes);
  fprintf oc "feature calt {\n%s\n} calt;\n\n" calt_lookups;
  fprintf oc "feature kern {\n%s\n} kern;\n" kern_lookups;
  close_out oc

let () = main ()
