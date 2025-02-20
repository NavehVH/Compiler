# Scheme to Assembly x86-64 bit Compiler in OCaml

## Overview
This project is a **Scheme-to-x86 compiler**, built in **OCaml**, as part of a Compiler Construction course at Ben-Gurion University. The compiler translates a subset of **Scheme** (a Lisp dialect) into **x86-64 assembly**, which can be executed on a Linux system.

The compiler follows a multi-stage pipeline, implementing **lexing, parsing, semantic analysis, optimization, and code generation**. It supports **tail-call optimization**, arithmetic operations, recursion, and function definitions.

## Features
✔ **Parsing of Scheme expressions** - Generates an Abstract Syntax Tree (AST).  
✔ **Static Type Checking** - Detects type mismatches at compile-time.  
✔ **Optimizations** - Includes **tail-call elimination** and **constant folding**.  
✔ **Code Generation** - Produces **x86-64 assembly code**.  
✔ **Bootstrapped in OCaml** - Implements a functional approach to compiler design.  

---

## Compiler Pipeline 🛠️
The compilation process follows a structured pipeline:

### 1️⃣ Lexical Analysis (Scanner)
- Converts raw Scheme **characters** into a sequence of **tokens**.
- Recognizes **keywords, identifiers, numbers, symbols, and parentheses**.
- Implemented using **regular expressions** and a **finite-state machine**.

### 2️⃣ Parsing (Reader & Tag-Parser)
- The **Reader** converts tokens into **S-expressions (sexprs)**, a tree-like structure.
- The **Tag-Parser** transforms **S-expressions** into **Abstract Syntax Trees (ASTs)**.
- Ensures correct **Scheme syntax**, including proper parenthesis matching and function definitions.

### 3️⃣ Semantic Analysis
- Checks **scope resolution, variable bindings, and function arity**.
- Detects **type mismatches**, **undefined variables**, and **invalid expressions**.
- Optimizes function calls by identifying **tail-recursive functions**.

### 4️⃣ Code Generation
- Translates the **AST** into **x86-64 assembly**.
- Implements **stack-based function calls**, register allocation, and control flow.
- Produces an **assembly (.asm) file**, which is compiled into an executable.

