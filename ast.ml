(********
 *
 * ast.ml 
 *
 * Aliaume Lopez
 *
 * This module contains the type definition 
 * and smart constructors for the abstract 
 * syntax tree of circuits. 
 *
 *) 

(*
 * Un type de circuit, avec en plus une information contenue 
 * dans chaque noeud 
 *)
type 'a circuit = Par    of  'a * 'a 
                | Seq    of  'a * 'a  
                | VarI   of string
                | VarO   of string
                | Const  of string * int * int
                | Id     of int
                | IdPoly    
                | Links  of (string * string) list * 'a;;

(* 
 * Prend un 'a circuit et applique une fonction 
 * à chaque trou 
 *)
let fmap f x = match x with
    | Par (a,b)      -> Par (f a, f b)
    | Seq (a,b)      -> Seq (f a, f b)
    | Links (x,c)    -> Links (x, f c)
    | VarI a         -> VarI a
    | VarO a         -> VarO a
    | Const (a,b,c)  -> Const (a,b,c)
    | Id n           -> Id n 
    | IdPoly         -> IdPoly;;

(* Le type de circuit récursif associé *)
type circ          = Circ  of circ circuit;; 
type 'a typed_circ = TCirc of ('a typed_circ circuit * 'a) 

(* L'extracteur *)
let unfix = function 
    | Circ x -> x;;

(* Le constricteur *)
let fix x = Circ x;;

let unfix_typed = function
    | TCirc x -> x;;

let fix_typed x = TCirc x;;


(* 
 *
 * Fix F ---- unfix ----> F (Fix F) 
 *  |                        |
 *  |                        |
 * fold g                  fmap (fold g)
 *  |                        |
 *  |                        |
 *  \/                      \/
 *  A    <---- g -------- F A
 *
 *)
let rec foldc g c = g (fmap (foldc g) (unfix c));; 
let rec foldc_typed g c = 
    let (a,b) = unfix_typed c in 
    g (fmap (foldc_typed g) a) b;;


let uid_var       = ref 0;; 
let newvarname () = incr uid_var; "v_" ^ string_of_int !uid_var ;;

(* Les petites fonctions qui aident bien dans la vie *)
let (===) a b    = match (a,b) with
    | (Circ IdPoly), _ -> b
    | _, (Circ IdPoly) -> a
    | _              -> Circ (Seq (a,b));;

let (|||) a b    = match (a,b) with
    | Circ (Const (_,0,0)), _ -> b
    | _, Circ (Const (_,0,0)) -> a
    | _                       -> Circ (Par (a,b));;

let vari x       = Circ (VarI x);;
let varo x       = Circ (VarO x);;
let const x y z  = Circ (Const (x,y,z));;
let id x         = Circ (Id x);;
let idpoly       = Circ IdPoly;;
let links l c    = Circ (Links (l,c));;

let symmetry     =
    let x = newvarname () in 
    let y = newvarname () in 
    let z = newvarname () in 
    let t = newvarname () in 
    links [(x,y);(z,t)] ((varo x) ||| (varo z) ||| (vari t) ||| (vari y));; 

let trace a      = 
    let x = newvarname () in 
    let y = newvarname () in 
    links [(x,y)] (((vari y) ||| idpoly) === a === ((varo x) ||| idpoly));;

let bindi y c    = 
    let x = newvarname () in 
    links [(x,y)] ((varo x) ||| c);;

let bindo x c    = 
    let y = newvarname () in 
    links [(x,y)] ((vari y) ||| c);;

let empty = Circ (Const ("unit", 0, 0));;


let print_ast c = 
    let print_aux = function
        | Const (x,y,z) -> x
        | Par (x,y) -> "(" ^ x ^ ") | (" ^ y ^ ")" 
        | Seq (x,y) -> "(" ^ x ^ ") o (" ^ y ^ ")" 
        | VarI y    -> ":" ^ y
        | VarO y    -> y ^ ":"
        | Id n      -> string_of_int n
        | IdPoly    -> "Id"
        | Links (l,x) -> l
                |> List.map (fun (a,b) -> a ^ ":" ^ b)  
                |> String.concat " "
                |> (fun y -> "links " ^ y ^ "." ^ x) 
    in 
    foldc print_aux c;;
