%skeleton "lalr1.cc"
%require "3.5"

%defines
%define api.token.constructor
%define api.value.type variant
%define parse.assert

%code requires {
    #include <string>
    /* Forward declaration of classes in order to disable cyclic dependencies */
    class Scanner;
    class Driver;
}


%define parse.trace
%define parse.error verbose

%code {
    #include "driver.hh"
    #include "location.hh"

    /* Redefine parser to use our function from scanner */
    static yy::parser::symbol_type yylex(Scanner &scanner) {
        return scanner.ScanToken();
    }
}

%lex-param { Scanner &scanner }

%parse-param { Scanner &scanner }
%parse-param { Driver &driver }

%locations

%define api.token.prefix {TOK_}
// token name in variable
%token
    END 0 "end of file"
    PRINTLN "println"
    TRUE "true"
    FALSE "false"
    IF "if"
    ELSE "else"
    FOR "for"
    ASSIGN "="
    MINUS "-"
    PLUS "+"
    STAR "*"
    SLASH "/"
    LPAREN "("
    RPAREN ")"
    LCURLY "{"
    RCURLY "}"
    SEMICOLON ";"
    BINAND "&"
    BINOR "|"
    BOOLNOT "!"
    BITNOT "~"
    EQ "=="
    NEQ "!="
    LT "<"
    LE "<="
    GT ">"
    GE ">="
    XOR "^"
;

%token <std::string> IDENTIFIER "identifier"
%token <int> NUMBER "number"
%nterm <int> assign
%nterm <int> exp
%nterm <int> printing
%nterm <int> for_loop
%nterm <int> assignment
%nterm <int> conditional
%nterm <int> unit

// Prints output in parsing option for debugging location terminal
%printer { yyo << $$; } <*>;

%%
%left "+" "-";
%left "*" "/";

%start unit;
unit: %empty { driver.result = 0; }
    | assignment unit {};
    | printing unit {};
    | for_loop unit {};
    | conditional unit {};

printing:
    "println" "(" exp ")" ";" {
        std::cout << $3 << std::endl;
    }

for_loop:
    "for" assign ";" exp ";" assign "{" unit "}" {
        for ($2; $4; $6) {
            $8;
        }
    }

conditional: if_closure {};
    | if_else_closure {}

if_else_closure:
    "if" exp "{" unit "}" "else" "{" unit "}" {
        if ($2) {
            $4;
        } else {
            $8;
        }
    }
    | "if" assign ";" exp "{" unit "}" "else" "{" unit "}" {
        $2;
        if ($4) {
            $6;
        } else {
            $10;
        }
    }

if_closure:
    "if" exp "{" unit "}" {
        if ($2) {
            $4;
        }
    }
    | "if" assign ";" exp "{" unit "}" {
        $2;
        if ($4) {
            $6;
        }
    }

assignment: assign ";"

assign:
    "identifier" "=" exp {
        driver.variables[$1] = $3;
        if (driver.location_debug) {
            std::cerr << driver.location << std::endl;
        }
    }



exp:
    "number"
    | "identifier" {$$ = driver.variables[$1];}
    | exp "+" exp {$$ = $1 + $3; }
    | exp "-" exp {$$ = $1 - $3; }
    | exp "*" exp {$$ = $1 * $3; }
    | exp "/" exp {$$ = $1 / $3; }
    | "(" exp ")" {$$ = $2; };
    | exp "<" exp {$$ = $1 < $3; }
    | exp "<=" exp {$$ = $1 <= $3; }
    | exp ">" exp {$$ = $1 > $3; }
    | exp ">=" exp {$$ = $1 >= $3; }
    | exp "==" exp {$$ = $1 == $3; }
    | exp "!=" exp {$$ = $1 != $3; }
    | exp "&" exp {$$ = $1 & $3; }
    | exp "|" exp {$$ = $1 | $3; }
    | "!" exp {$$ = ! $2; }
    | "~" exp {$$ = ~ $2; }
    | "-" exp {$$ = - $2; }
    | "+" exp {$$ = + $2; }
    | exp "^" exp {$$ = $1 ^ $3; }
    | "false" {$$ = false; }
    | "true" {$$ = true; }

%%

void
yy::parser::error(const location_type& l, const std::string& m)
{
  std::cerr << "ERROR: " << l << ": " << m << '\n';
}
