open Ast
open Symboltable
(*adding testing comment *)
module StringMap = Map.Make(String)

let string_of_vtype = function
	 IntType -> "int"
  | StrType -> "string"
  | BoolType -> "bool"
  | JsonType -> "json"
  | ListType -> "list"

let get_sast_type = function
	Ast.JsonType -> Sast.JsonType
	| Ast.StrType -> Sast.StrType
	| Ast.IntType -> Sast.IntType
	| Ast.BoolType -> Sast.BoolType
	| Ast.ListType -> Sast.ListType


(* get variable type according to the name
 * raise error if no name matching in variable list *)
let get_vtype env id = 
	(* find_variable method is from the symbol table *)
	let t = find_variable id env in
	if t = "" then raise (Failure ("undefined variable: " ^ id)) else t

(* get the type of expression:
 *  -> string if one of the two operands having string type
 *  -> int/boolean if both of the operands having the same type *)
let get_expr_type t1 t2 =
	if t1 = "void" || t2 = "void" then raise (Failure ("cannot use void type inside expression")) else
	if t1 = "string" || t2 = "string" then "string" else
	if t1 = "int" && t2 = "int" then "int" else
	if t1 = "bool" && t2 = "bool" then "bool" else
	if t1 = "int" && t2 = "bool" then "int" else
	if t1 = "bool" && t2 = "int" then "int" else
	raise (Failure ("type error"))




(* check the expression type can be used for
 * the corresponding argument according to definition
 * return the new expression list in expr_t for sast *)
let check_func_arg lst expr arg_t =
	if (snd expr) = arg_t then (fst expr)::lst else
	raise (Failure("function arguments do not match"))

let match_oper e1 op e2 =
	(* snd of expr is type *)
	let expr_t = get_expr_type (snd e1) (snd e2) in
	(match op with
	   Ast.Add -> if expr_t = "int" then (Sast.Binop(fst e1, Sast.Add, fst e2), "int") else
		  		raise (Failure ("type error"))
	 | Ast.Sub -> if expr_t = "int" then (Sast.Binop(fst e1, Sast.Sub, fst e2), "int") else
		  raise (Failure ("type error"))
	 | Ast.Mult -> if expr_t = "int" then (Sast.Binop(fst e1, Sast.Mult, fst e2), "int") else
	 	   raise (Failure ("type error"))
	 | Ast.Div -> if expr_t = "int" then (Sast.Binop(fst e1, Sast.Div, fst e2), "int") else
		  raise (Failure ("type error"))
		  (* equal and not equal have special case for string comparison 
		  		we may need to add SAST and Eqs and Neqs *)
	 | Ast.Equal -> if expr_t = "int" then (Sast.Binop(fst e1, Sast.Equal, fst e2), "bool") else
                  raise (Failure ("type error in == "))
	 | Ast.Neq -> if expr_t = "int" then (Sast.Binop(fst e1, Sast.Neq, fst e2), "bool") else
                  raise (Failure ("type error"))
	 | Ast.Less ->if expr_t = "int" then (Sast.Binop(fst e1, Sast.Less, fst e2), "bool") else
                  raise (Failure ("type error")) 
	 | Ast.Leq ->if expr_t = "int" then (Sast.Binop(fst e1, Sast.Leq, fst e2), "bool") else
                  raise (Failure ("type error"))
	 | Ast.Greater ->if expr_t = "int" then (Sast.Binop(fst e1, Sast.Greater, fst e2), "bool") else
                  raise (Failure ("type error"))
	 | Ast.Geq ->if expr_t = "int" then (Sast.Binop(fst e1, Sast.Geq, fst e2), "bool") else
                  raise (Failure ("type error")) 
     | Ast.And ->if expr_t = "bool" then (Sast.Binop(fst e1, Sast.And, fst e2), "bool") else
      			  raise (Failure ("type error in and")) 
     | Ast.Or ->if expr_t = "bool" then (Sast.Binop(fst e1, Sast.Or, fst e2), "bool") else
      			  raise (Failure ("type error in or")) 
	)

(* it returns the expr and its type *)
let rec check_expr env = function
	Ast.LitInt(i) -> 
		let _ = print_string "in int" in
		Sast.LitInt(i), "int"

	| Ast.LitStr(s) -> 
		let _ = print_string "in string " in
		Sast.LitStr(s), "string"

	| Ast.Id(id) ->
		let _ = print_string "in iD" in
		Sast.Id(id), (get_vtype env id)

	| Ast.Binop(e1, op, e2) ->
		let _ = print_string "in binop" in
		match_oper (check_expr env e1) op (check_expr env e2)

	| Ast.Assign(id, e) ->
		let _ = print_string "in assign" in
		let t = get_vtype env id in
		(* if t = "string" then 
		     Ast.AssignStr(id, (conv_type (check_expr env e))), "void"
		else  *)
		Sast.Assign(id, (get_expr_with_type env e t)), "void"
	
	| Ast.NoExpr -> Sast.NoExpr, "void"


(* get expr_t(sast type) by expr(ast type) with given type
 * raise error if the expression type does match requirement, snd e has the type and fst has the expr *)
and get_expr_with_type env expr t = 
	let e = check_expr env expr in
	(* added special case for the path variable *)
	fst e


	
let rec check_stmt env func = function
	Ast.Expr(expr) -> (Sast.Expr(fst (check_expr env expr))), env

and check_stmt_list env func = function 
	  [] -> []
	| hd::tl -> let s,e = (check_stmt env func hd) in s::(check_stmt_list e func tl)

(* convert a variable to its SAST type *)
let convert_to_sast_type x env = 
	let t = get_vtype env x.vname in
		let s_expr = 
		if not (x.vexpr = Ast.NoExpr) then
			get_expr_with_type env x.vexpr t
		else Sast.NoExpr
		in
	{
		Sast.vtype = get_sast_type x.vtype;
		Sast.vname = x.vname;
		Sast.vexpr = s_expr;
	}

let check_formal env formal = 
	let ret = add_local formal.vname formal.vtype env in
	if (string_of_vtype formal.vtype) = "void" then raise (Failure("cannot use void as variable type")) else
	if StringMap.is_empty ret then raise (Failure ("local variable " ^ formal.vname ^ " is already defined"))
	(* update the env with locals from ret *)
	else let env = {locals = ret; globals = env.globals; functions = env.functions } in
	convert_to_sast_type formal env, env

let rec check_formals env formals = 
	match formals with 
	  [] -> []
	| hd::tl -> let f, e = (check_formal env hd) in (f, e)::(check_formals e tl) 


let check_local env local =
	let ret = add_local local.vname local.vtype env in
	if (string_of_vtype local.vtype) = "void" then raise (Failure("cannot use void as variable type")) else
	if StringMap.is_empty ret then raise (Failure ("local variable " ^ local.vname ^ " is already defined"))
	(* update the env with globals from ret *)
	else let env = {locals = ret; globals = env.globals; functions = env.functions } in
	convert_to_sast_type local env, env

let rec check_locals env locals = 
	match locals with
	  [] -> []
	| hd::tl -> let l, e = (check_local env hd) in (l, e)::(check_locals e tl)

(* this function will return the updated formals and body as per the abstract syntax tree, the return type, name and locals *)
let check_function env func =
	(* if List.length func.body = 0 then raise (Failure ("The last statement must be return statement"))
	else if func.fname = "main" && (List.length func.formals) > 0 
	then raise (Failure ("The main function cannot take any argument"))
	else if  func.fname = "main" && ((func.returnType = "int") || (func.returnType = "boolean"))
	then raise (Failure ("The main function cannot can only has type void"))
	else  *)
	match List.hd (List.rev func.body) with
	Return(_) ->
	  	let env = {locals = StringMap.empty; globals = env.globals; functions = env.functions } in
	  	(*  ret is new env *)
		let ret = add_function func.fname func.return func.formals env in
		if StringMap.is_empty ret then raise (Failure ("function " ^ func.fname ^ " is already defined"))
		(* update the env with functions from ret *)
		else let env = {locals = env.locals; globals = env.globals; functions = ret } in
		(* check the formal arguments, returns formal list appended with their env *)
		let f = check_formals env func.formals in
		(* get the list of formals from f *)
		let formals = List.map (fun formal -> fst formal) f in
		
		(* get the final env from the last formal *)
		let l, env = 
		(match f with
			  [] -> let l = check_locals env func.fnlocals in
					 l, env
			| _ -> 	let env = snd (List.hd (List.rev f)) in
					let l = check_locals env func.fnlocals in
					l, env
		) in
		let fnlocals = List.map (fun fnlocal -> fst fnlocal) l in
		 (match l with
		 	(* empty f, no fomal args *)
	            [] -> let body = check_stmt_list env func func.body in
	                { Sast.return = get_sast_type func.return; 
	                  Sast.fname = func.fname; 
	                  Sast.formals = formals; 
	                  Sast.fnlocals = fnlocals; 
	                  Sast.body = body
	                }, env

	            (* get the final env from the last formal *)
	            | _ -> let e = snd (List.hd (List.rev l)) in
	                   let body = check_stmt_list e func func.body in
	                  { Sast.return = get_sast_type func.return; 
	                    Sast.fname = func.fname; 
	                    Sast.formals = formals; 
	                    Sast.fnlocals = fnlocals; 
	                    Sast.body = body
	                  }, e 
          )

	| _ -> raise (Failure ("The last statement must be return statement"))


let rec check_functions env funcs = 
	match funcs with
	  [] -> []
	| hd::tl -> let f, e = (check_function env hd) in f::(check_functions e tl) 

(* returns the global and its env *)
let check_global env global =
 	let _ = print_string "in iD" in
	let ret = add_global global.vname global.vtype env in
	if StringMap.is_empty ret then raise (Failure ("global variable " ^ global.vname ^ " is already defined"))
	(* update the env with globals from ret *)
	else let env = {locals = env.locals; globals = ret; functions = env.functions } in
	convert_to_sast_type global env, env

let rec check_globals env globals = 
	match globals with
	  [] -> []
	| hd::tl -> let g, e = (check_global env hd) in (g, e)::(check_globals e tl)

let check_program (globals, funcs) = 
	(* create the default environment *)
 	let env = {	locals = StringMap.empty;
				globals = StringMap.empty;
				functions = StringMap.empty }
	in
	(* return the list of each global appended with its environments, the last global has the final env *)
	let g = check_globals env globals in
	(* make a list of globals *)
	let globals = List.map (fun global -> fst global) g in
	match g with
	(* no globals *)
	 [] -> (globals, (check_functions env (List.rev funcs)))
	(* get the envirnment from the last global *)
	| _ -> let e = snd (List.hd (List.rev g)) in (globals, (check_functions e (List.rev funcs)))