type op_t = Add | Sub | Mult | Div | Equal | Neq | Less | Leq | Greater | Geq | And | Or 

type data_type_t = StrType | IntType | BoolType | JsonType | ListType

type expr_t =
    LitInt of int
  | LitStr of string
	| LitJson of string
  | LitList of string
  | Id of string
  | Binop of expr_t * op_t * expr_t
  | Assign of string * expr_t
  | NoExpr

type stmt_t =
	 Expr of expr_t
  | Return of expr_t


type var_decl_t = {
  vtype : data_type_t;
  vname : string;
  vexpr : expr_t;
}

type func_decl_t = {
    return : data_type_t;
    fname : string;
    formals : var_decl_t list;
    fnlocals : var_decl_t list;
    body : stmt_t list;
  }

type program_t = var_decl_t list * func_decl_t list