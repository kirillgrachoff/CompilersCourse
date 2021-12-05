%skeleton "lalr1.cc"
%require "3.5"

%defines
%define api.token.constructor
%define api.value.type variant
%define parse.assert

%code requires {
    #include <string>
    #include <memory>
    /* Forward declaration of classes in order to disable cyclic dependencies */
    class Scanner;
    class Driver;
    class Expression;
    template <typename Function>
    class ExpressionInt;
    template <typename Function>
    class ExpressionString;
    template <typename Function>
    class ExpressionBoth;
    template <typename Function>
    class UnaryExpressionInt;
    template <typename Function>
    class UnaryExpressionString;
}


%define parse.trace
%define parse.error verbose

%code {
    #include "driver.hh"
    #include "location.hh"
    #include "expression.h"

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
%nterm <std::shared_ptr<Expression>> exp
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
        for ($2; std::get<int>($4->get()); $6) {
            $8;
        }
    }
    | "for" assign ";" exp "{" unit "}" {
        $2;
        while (std::get<int>($4->get())) {
            $6;
        }
    }
    | "for" exp "{" unit "}" {
        while (std::get<int>($2->get())) {
            $4;
        }
    }

conditional: if_closure {};
    | if_else_closure {}

if_else_closure:
    "if" exp "{" unit "}" "else" "{" unit "}" {
        if (std::get<int>($2->get())) {
            $4;
        } else {
            $8;
        }
    }
    | "if" assign ";" exp "{" unit "}" "else" "{" unit "}" {
        $2;
        if (std::get<int>($4->get())) {
            $6;
        } else {
            $10;
        }
    }

if_closure:
    "if" exp "{" unit "}" {
        if (std::get<int>($2->get())) {
            $4;
        }
    }
    | "if" assign ";" exp "{" unit "}" {
        $2;
        if (std::get<int>($4->get())) {
            $6;
        }
    }

assignment: assign ";"

assign:
    "identifier" "=" exp {
        driver.variables[$1] = $3->get();
        if (driver.location_debug) {
            std::cerr << driver.location << std::endl;
        }
    }



exp:
    "number" {$$ = new_value($1); }
    | "identifier" {$$ = std::make_shared<Variable>($1, driver); }
    | exp "+" exp {$$ = new_expression<ExpressionBoth>($1, $3, [](auto a, auto b) { return a + b; }); }
    | exp "-" exp {$$ = new_expression<ExpressionInt>($1, $3, [](auto a, auto b) { return a - b; }); }
    | exp "*" exp {$$ = new_expression<ExpressionInt>($1, $3, [](auto a, auto b) { return a * b; }); }
    | exp "/" exp {$$ = new_expression<ExpressionInt>($1, $3, [](auto a, auto b) { return a / b; }); }
    | "(" exp ")" {$$ = $2; };
    | exp "<" exp {$$ = new_expression<ExpressionBoth>($1, $3, [](auto a, auto b) { return a < b; }); }
    | exp "<=" exp {$$ = new_expression<ExpressionBoth>($1, $3, [](auto a, auto b) { return a <= b; }); }
    | exp ">" exp {$$ = new_expression<ExpressionBoth>($1, $3, [](auto a, auto b) { return a > b; }); }
    | exp ">=" exp {$$ = new_expression<ExpressionBoth>($1, $3, [](auto a, auto b) { return a >= b; }); }
    | exp "==" exp {$$ = new_expression<ExpressionBoth>($1, $3, [](auto a, auto b) { return a == b; }); }
    | exp "!=" exp {$$ = new_expression<ExpressionBoth>($1, $3, [](auto a, auto b) { return a != b; }); }
    | exp "&" exp {$$ = new_expression<ExpressionInt>($1, $3, [](auto a, auto b) { return a & b; }); }
    | exp "|" exp {$$ = new_expression<ExpressionInt>($1, $3, [](auto a, auto b) { return a | b; }); }
    | "!" exp {$$ = new_expression<UnaryExpressionInt>($2, [](auto a) { return !a; }); }
    | "~" exp {$$ = new_expression<UnaryExpressionInt>($2, [](auto a) { return ~a; }); }
    | "-" exp {$$ = new_expression<UnaryExpressionInt>($2, [](auto a) { return -a; }); }
    | "+" exp {$$ = new_expression<UnaryExpressionInt>($2, [](auto a) { return +a; }); }
    | exp "^" exp {$$ = new_expression<ExpressionInt>($1, $3, [](auto a, auto b) { return a ^ b; }); }
    | "false" {$$ = new_value(0); }
    | "true" {$$ = new_value(1); }

%%

void
yy::parser::error(const location_type& l, const std::string& m)
{
  std::cerr << "ERROR: " << l << ": " << m << '\n';
}
