# Compiling to diagrams

Definition of a langage to express circuit diargams
and the compilator associated.

## Dependencies

This program needs 

* A recent version of the ocaml compiler 
* GNU Make 

## Building and running 

To run the tests use 

```
make tests
```

To compile and run the circuits 

```
make circuits 
```

Once it is built, you will be able to use it with the following 
console command :

```
./circuits
```

Note that the default circuit is obtained by reading `lines.txt`, 
but any alternative text file can be used by supplying the filename 
as an argument :

```
./circuits filename
```

The graphics are generated in a separate directory called `graphics`.


## Syntax overview 

The syntax to describe circuits is pretty simple, and has three different
type of expressions. First of all, a circuit is represented by an expression,
and expressions can be _composed_ to create bigger circuits, this is what 
the base syntax allows for. Even if every circuit can be expressed in that way,
it is often convenient to use variables to name inputs and outputs of circuits,
and use the same variable across the construction, this is what the variable binding 
is about. Finally, sometimes the variables are to be linked together, an never 
used again (linking port of circuits), this is the last part.

### Base syntax

The basic circuits are the following ones

1. The identity circuit `n` which is the identity for n wires
2. The fork operator `f` and it's dual the join operator `j`
3. The disconnected wire `_|_` and the forget `w` 
4. The trace operator
5. The switch operator


### Syntax Definition

#### Constant circuits

The constant circuits are in capital letters. The following circuits are available

* FORK
* JOIN
* MUX
* NMOS (first entry = G, second entry = S)
* PMOS (first entry = G, second entry = S)
* BOT  (value bottom)
* TOP  (value illegal)
* HIGH (value high)
* LOW  (value low)
* DISC (disconnect gate)
* WAIT (delay node)
* Any other capital letter circuit is considered as a « box » with type 1->1, except `F`, `G` and `H` (for debugging purpose) and circuit that are declared 

The symmetry is not a circuit yet.

#### Operators 

Link operator works with the syntax

```
link a:b c:d ... for CIRCUIT
```

There is also the `.` for sequential composition and the `|` for parallel composition.

The trace is not an operator yet, because it can be replaced by link.

#### SEQ and PAR

Inside a `SEQ ... END` bloc the newlines are replaced with sequential composition of the lines (with implicit parenthesis
around each line). The same goes for parallel composition and `PAR ... END`.

#### LET construction

In order to define complex circuits it is often needed to build separate subcircuits and use them one or several time 
in a bigger expression : this is the only thing that the `let` construction does.

The syntax is the following :

```
let NameStartingWithACapitalLetter = regular circuit syntax  in
...
let ... = ... in 
main circuit definition 
```

Note that the variable substitution is done textually, meaning that the circuit is _copied_ into the places of use. 
Therefore, if the expression contains free variables, they can be bound differently in each use of the circuit, an 
example can illustrate this behaviour :

```
let SingleVariable = :a in 
(link b:a for ( b: | SingleVariable)) | (link c:a for SingleVariable . c:)
```

```
(link b:a for ( b: | :a)) | (link c:a for :a . c:)
```

Note that variable can be used inside `let` expressions, just like in ocaml : 

```
let Variable1 = expr1 in 
let Variable2 = expr2 that can contain Variable1 in 
...
```

There is no way to express mutually recursive definition with let bindings, as it would mean constructing circuits
with infinite depth.

### Building circuits with the AST direcly 

It is possible to direcly generate AST code by importing `ast.ml` and then printing it into a file 
with the pretty printing function in `ast.ml`. 

Ast construction is made simple by the helper functions to construct it 

```ocaml
val ( === )   : circ                   -> circ   -> circ
val ( ||| )   : circ                   -> circ   -> circ
val vari      : string                 -> circ
val varo      : string                 -> circ
val const     : string                 -> int    -> int  -> circ
val id        : int                    -> circ
val idpoly    : circ
val links     : (string * string) list -> circ   -> circ
val symmetry  : circ
val trace     : circ                   -> circ
val bindi     : string                 -> circ   -> circ
val bindo     : string                 -> circ   -> circ
val empty     : circ
val print_ast : circ                   -> string
```

The other circuits (constant circuits) are constructed 
using the `const` operator and setting the string parameter 
with the name of the circuit you want. The list of
reserved circuit names and their meaning is described in 
the constant circuit section of the syntax.
