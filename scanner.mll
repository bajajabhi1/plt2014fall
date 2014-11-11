{ open Parser }

let letter = ['a' - 'z' 'A' - 'Z']
let digit = ['0' - '9']
let quote = '"'

rule token = parse
	[' ' '\r' '\n' '\t']	{ token lexbuf }	| "/*"		{ comment lexbuf }
	| '('			{ LPAREN }		| ')'			{ RPAREN }
	| '{'			{ LBRACE }		| '}'			{ RBRACE }
(*	| ','			{ COMMA } *)
	| "++"			{ PLUS }		| "--"			{ MINUS }
	| "**"			{ TIMES }		| "//"			{ DIVIDE }
	| '='			{ ASSIGN }		| ';'			{ SEMI }
	| "=="			{ EQ }			| "!="			{ NEQ }
(*	| '<'			{ LT }			| "<="			{ LEQ }
	| '>'			{ GT }			| ">="			{ GEQ }
	| '['			{ LBRACK }		| ']'			{ RBRACK }
	| "&&"			{ AND }			| "||"			{ OR }
	| '!'			{ NOT }			| ".name"		{ PATHNAME }
	| "def"			{ DEF }			| ".created_at"	{ PATHCREATED }
	| "int"			{ INT }			| ".kind"		{ PATHKIND }
	| "path"		{ PATH }
	| "string"		{ STR }			| "list"		{ LIST } *)
	| "print"		{ PRINT } (*| "if"			{ IF }			| "else"		{ ELSE }
	| "then"		{ THEN }		
	| "for"			{ FOR }			| "in"			{ IN }
	| "do"			{ DO }			| "bool"		{ BOOL }
	| "while"		{ WHILE }		| "return"		{ RETURN }
	| "void"		{ VOID } 		| ".add"		{ ADD }
	| "true"		{ TRUE }		| ".remove"		{ REMOVE }
	| "false"		{ FALSE }		| ".type"		{ PATHEXT } *)
	| eof			{ EOF }			(* do as microC *)
	| digit+ as lit					{ LIT_INT(int_of_string lit) }
	| quote [^'"']* quote as lit	{ LIT_STR(lit) } 
	| "#{" _* "}#" as lit { LIT_JSON(lit) }
	| "#[" _* "]#" as lit { LIT_LIST(lit) }
	| letter | (letter | digit | '_')* as id		{ ID(id) }
	| _ as char 		{ raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
	"*/"			{ token lexbuf }
	| _				{ comment lexbuf}