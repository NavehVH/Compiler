(* pc.ml
 * The new implementation of the parsing-combinators package for ocaml
 *
 * Programmer: Mayer Goldberg, 2024
 *)

(* general list-processing procedures *)

(* takes a string and return list of its characters *)
let list_of_string string =
  let rec run i s =
    if i < 0 then s
    else run (i - 1) (string.[i] :: s) in
  run (String.length string - 1) [];;


(* takes list of chars and return the string they create *)
let string_of_list s =
  List.fold_left (* does the code from the "left side" *)
    (fun str ch -> str ^ (String.make 1 ch)) (* takes a function *)
    "" (* accumulator *)
    s;; (* list to process *)

let string_of_file input_file =
  let in_channel = open_in input_file in
  let rec run () =
    try 
      let ch = input_char in_channel in ch :: (run ())
    with End_of_file ->
      ( close_in in_channel;
	[] )
  in string_of_list (run ());;

  (* OR on a predicat and a list, returns true for the first value that will return it *)
let rec ormap f s =
  match s with
  | [] -> false
  | car :: cdr -> (f car) || (ormap f cdr);;

   (* AND on a predicat and a list, returns false if there is a value with false *)
let rec andmap f s =
  match s with
  | [] -> true
  | car :: cdr -> (f car) && (andmap f cdr);;	  

  (* write PC.method or do #open PC;; to use *)
module PC = struct

  (* describing the parsing we did as "output" *)
  type 'a parsing_result = {
      index_from : int; (* staring index *)
      index_to : int; (* end index *)
      found : 'a (* what we found *)
    };;

  type 'a parser = string -> int -> 'a parsing_result;;

  (* the parsing combinators defined here *)
  
  exception X_not_yet_implemented of string;; (* use if didnt code it yet *)

  exception X_no_match;; (* if it didn't find anything we return this *)

    (* check if the predicat is true, and return the info of parsing result *)
  let const pred = (* gets predicat, str to check and starting index *)
    ((fun str index ->
      if (index < String.length str) && (pred str.[index])
      then {
          index_from = index;
          index_to = index + 1;
          found = str.[index]
        }
      else raise X_no_match) : 'a parser);;

      (* Doing concatenation of 2 parsers, 1 after another. (can be diff types) *)
      (* if one of them fails, raises no match*)
  let caten (nt_1 : 'a parser) (nt_2 : 'b parser) =
    ((fun str index ->
      let {index_from = index_from_1;
           index_to = index_to_1;
           found = e_1} = (nt_1 str index) in
      let {index_from = index_from_2;
           index_to = index_to_2;
           found = e_2} = (nt_2 str index_to_1) in (* doing the second parser right after the first one finishes *)
      {index_from = index_from_1;
       index_to = index_to_2;
       found = (e_1, e_2)}) : (('a * 'b) parser));; (* returns a tuple of the types *)

       (* gets a parser and a function, and can define a different type of "found" result in the parsing result*)
       (* we will use it everytime we want to change the the parser returns *)
  let pack (nt : 'a parser) (f : 'a -> 'b) =
    ((fun str index -> (* str to check and starting index *)
      let {index_from; index_to; found} = (nt str index) in
      {index_from; index_to; found = (f found)})
     : 'b parser);;

     (* "nothing", "empty", "empty list" *)
  let nt_epsilon =
    ((fun str index ->
      {index_from = index;
       index_to = index;
       found = []}) : 'a parser);;

  (* caten list of parsers with the same type *)
  let caten_list nts =
    List.fold_right
      (fun nt1 nt2 ->
        pack (caten nt1 nt2)
	  (fun (e, es) -> (e :: es)))
      nts
      nt_epsilon;;

      (* will try to do first parser, else it will try to do the second one *)
  let disj (nt1 : 'a parser) (nt2 : 'a parser) =
    ((fun str index -> 
      try (nt1 str index)
      with X_no_match -> (nt2 str index)) : 'a parser);;

  let nt_none = ((fun _str _index -> raise X_no_match) : 'a parser);;
  let nt_fail = nt_none;;
  
   (* disj to a list of parsers *)
  let disj_list nts = List.fold_right disj nts nt_none;;

  (* said will talk later *)
  let delayed (thunk : unit -> 'a parser) =
    ((fun str index -> thunk() str index) : 'a parser);;

    (* end of input *)
  let nt_end_of_input str index = 
    if (index < String.length str)
    then raise X_no_match
    else {index_from = index; index_to = index; found = []};;

    (* gets a parser nt and returns if there 0 or more instances that been found by nt*)
  let rec star (nt : 'a parser) =
    ((fun str index ->
      try let {index_from = index_from_1;
               index_to = index_to_1;
               found = e} = (nt str index) in
          let {index_from = index_from_rest;
               index_to = index_to_rest;
               found = es} = (star nt str index_to_1) in
          {index_from = index_from_1;
           index_to = index_to_rest;
           found = (e :: es)}
      with X_no_match -> {index_from = index; index_to = index; found = []})
     : 'a list parser);;

    (* gets a parser nt and returns if there 1 or more instances that been found by nt*)
  let plus nt =
    pack (caten nt (star nt))
      (fun (e, es) -> (e :: es));;

    (* gets a parser nt and returns if there exacly n instances that been found by nt*)
  let rec power nt = function
    | 0 -> nt_epsilon
    | n -> pack(caten nt (power nt (n - 1)))
            (fun (e, es) -> e :: es);;    

    (* gets a parser nt and returns if there at least n instances that been found by nt*)
  let at_least nt n =
    pack (caten (power nt n) (star nt))
      (fun (es_1, es_2) -> es_1 @ es_2);;

      (* "guard" if it found something it will return it?.. he didnt show an exmaple*)
  let only_if (nt : 'a parser) pred =
    ((fun str index ->
      let ({index_from; index_to; found} as result) = (nt str index) in
      if (pred found) then result
      else raise X_no_match) : 'a parser);;

      (* checks if something maybe in the parser, like if parser checks for * and it found it will return found=Some '*', else none. *)
  let maybe (nt : 'a parser) =
    ((fun str index ->
      try let {index_from; index_to; found} = (nt str index) in
          {index_from; index_to; found = Some(found)}
      with X_no_match ->
        {index_from = index; index_to = index; found = None})
     : 'a option parser);;  

     (* if i have a nt1 parser that checks if 0-9 and a-z, and nt2 is 0-9. So the diff is a-z.*)
  let diff nt1 nt2 =
    ((fun str index ->
      match (maybe nt1 str index) with
      | {index_from; index_to; found = None} -> raise X_no_match
      | {index_from; index_to; found = Some(e)} ->
         match (maybe nt2 str index) with
         | {index_from = _; index_to = _; found = None} ->
            {index_from; index_to; found = e}
         | _ -> raise X_no_match) : 'a parser);;

    (* check if nt1 followed by nt2 next (?) *)
  let followed_by (nt1 : 'a parser) (nt2 : 'b parser) =
    ((fun str index -> 
      let ({index_from; index_to; found} as result) = (nt1 str index) in
      let _ = (nt2 str index_to) in
      result) : 'a parser);;

      (* check if nt1 is not followed by nt2 next *)
        (* if nt1 = 'a', 'a' will be found, 'aX' will be found, 'ab' won't *)
  let not_followed_by (nt1 : 'a parser) (nt2 : 'b parser) =
    ((fun str index ->
      match (let ({index_from; index_to; found} as result) = (nt1 str index) in
	     try let _ = (nt2 str index_to) in
	         None
	     with X_no_match -> (Some(result))) with
      | None -> raise X_no_match
      | Some(result) -> result) : 'a parser);;
  
  (* useful general parsers for working with text *)

  let make_char equal ch1 = const (fun ch2 -> equal ch1 ch2);;

  let char = make_char (fun ch1 ch2 -> ch1 = ch2);; (* recognize a char *)

  let char_ci = (* recognize a char but case insensitive *)
    make_char (fun ch1 ch2 ->
	(Char.lowercase_ascii ch1) =
	  (Char.lowercase_ascii ch2));;

  let make_word char str = 
    List.fold_right
      (fun nt1 nt2 -> pack (caten nt1 nt2) (fun (a, b) -> a :: b))
      (List.map char (list_of_string str))
      nt_epsilon;;

  let word = make_word char;; (* recognize a word *)
  (* for example: word "moshe" "moshe is dumb", will find it!*)

  let word_ci = make_word char_ci;; (* recognize a word but case insensitive *)
  (* Will also find MOSHE *)

  let make_one_of char str =
    List.fold_right
      disj
      (List.map char (list_of_string str))
      nt_none;;

  let one_of = make_one_of char;;

  let one_of_ci = make_one_of char_ci;;

  let nt_whitespace = const (fun ch -> ch <= ' ');;

  let make_range leq ch1 ch2 =
    const (fun ch -> (leq ch1 ch) && (leq ch ch2));;

  let range = make_range (fun ch1 ch2 -> ch1 <= ch2);;

  let range_ci =
    make_range (fun ch1 ch2 ->
	(Char.lowercase_ascii ch1) <=
	  (Char.lowercase_ascii ch2));;

  let nt_any = ((fun str index -> const (fun ch -> true) str index) : 'a parser);;

  let trace_pc desc (nt : 'a parser) =
    ((fun str index ->
      try let ({index_from; index_to; found} as value) = (nt str index)
          in
          (Printf.printf ";;; %s matched from char %d to char %d, leaving %d chars unread\n"
	     desc
	     index_from index_to
             ((String.length str) - index_to) ;
           value)
      with X_no_match ->
        (Printf.printf ";;; %s failed\n"
	   desc ;
         raise X_no_match)) : 'a parser);;

  let unitify nt = pack nt (fun _ -> ());;

  let make_separated_by_power nt_sep n nt =
    let nt1 = pack (caten nt_sep nt) (fun (_, e) -> e) in
    let nt1 = caten nt (power nt1 n) in
    let nt1 = pack nt1 (fun (e, es) -> e :: es) in
    nt1;;

  let make_separated_by_plus nt_sep nt =
    let nt1 = pack (caten nt_sep nt) (fun (_, e) -> e) in
    let nt1 = caten nt (star nt1) in
    let nt1 = pack nt1 (fun (e, es) -> e :: es) in
    nt1;;

  let make_separated_by_star nt_sep nt =
    let nt1 = make_separated_by_plus nt_sep nt in
    let nt1 = pack (maybe nt1)
                (function
                 | None -> []
                 | Some es -> es) in
    nt1;;  

  (* testing the parsers *)

  let test_string (nt : 'a parser) str index =
    nt str index;;

  let search_forward (nt : 'a parser) str =
    let limit = String.length str in
    let rec run i =
      if (i < limit)
      then (match (maybe nt str i) with
            | {index_from; index_to; found = None} -> run (i + 1)
            | {index_from; index_to; found = Some(e)} ->
               {index_from; index_to; found = e})
      else raise X_no_match in
    run 0;; 

  let search_forward_all_with_overlap (nt : 'a parser) str =
    let limit = String.length str in
    let rec run i = 
      if (i < limit)
      then (match (maybe nt str i) with
            | {index_from; index_to; found = None} -> run (i + 1)
            | {index_from; index_to; found = Some(e)} ->
               {index_from; index_to; found = e} :: (run (i + 1)))
      else [] in
    run 0;;

  let search_forward_all_without_overlap (nt : 'a parser) str =
    let limit = String.length str in
    let rec run i = 
      if (i < limit)
      then (match (maybe nt str i) with
            | {index_from; index_to; found = None} -> run (i + 1)
            | {index_from; index_to; found = Some(e)} ->
               {index_from; index_to; found = e} :: (run index_to))
      else [] in
    run 0;;

  let search_backward (nt : 'a parser) str =
    let rec run i =
      if (-1 < i)
      then (match (maybe nt str i) with
            | {index_from; index_to; found = None} -> run (i - 1)
            | {index_from; index_to; found = Some(e)} ->
               {index_from; index_to; found = e})
      else raise X_no_match in
    run (String.length str - 1);; 

  let search_backward_all_with_overlap (nt : 'a parser) str =
    let limit = String.length str in
    let rec run i = 
      if (-1 < i)
      then (match (maybe nt str i) with
            | {index_from; index_to; found = None} -> run (i - 1)
            | {index_from; index_to; found = Some(e)} ->
               {index_from; index_to; found = e} :: (run (i - 1)))
      else [] in
    run (limit - 1);;

end;; (* end of struct PC *)

(* end-of-input *)
