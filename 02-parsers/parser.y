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

    class Runnable;
    class RunnableEmpty;
    class RunnableSeq;
    class RunnableFor;
    class RunnableIf;
    class RunnablePrint;
    class RunnableAssign;
}


%define parse.trace
%define parse.error verbose

%code {
    #include "driver.hh"
    #include "location.hh"
    #include "expression.h"
    #include "runnable.h"

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
%nterm <std::shared_ptr<Runnable>> assign
%nterm <std::shared_ptr<Expression>> exp
%nterm <std::shared_ptr<Runnable>> printing
%nterm <std::shared_ptr<Runnable>> for_loop
%nterm <std::shared_ptr<Runnable>> if_closure
%nterm <std::shared_ptr<Runnable>> if_else_closure
%nterm <std::shared_ptr<Runnable>> assignment
%nterm <std::shared_ptr<Runnable>> conditional
%nterm <std::shared_ptr<Runnable>> unit

// Prints output in parsing option for debugging location terminal
%printer { yyo << $$; } <*>;

%%
%left "+" "-";
%left "*" "/";

%start Unit;
Unit: unit { driver.add_executable($1); };

unit: %empty { driver.result = 0; $$ = std::make_shared<RunnableEmpty>(); };
    | assignment unit { $$ = std::make_shared<RunnableSeq>($1, $2); };
    | printing unit { $$ = std::make_shared<RunnableSeq>($1, $2); };
    | for_loop unit { $$ = std::make_shared<RunnableSeq>($1, $2); };
    | conditional unit { $$ = std::make_shared<RunnableSeq>($1, $2); };

printing:
    "println" "(" exp ")" ";" {
        $$ = std::make_shared<RunnablePrint>($3);
    }

for_loop:
    "for" assign ";" exp ";" assign "{" unit "}" {
        $$ = std::make_shared<RunnableFor>($2, $4, $6, $8);
    }
    | "for" assign ";" exp "{" unit "}" {
        $$ = std::make_shared<RunnableFor>($2, $4, nullptr, $6);
    }
    | "for" exp "{" unit "}" {
        $$ = std::make_shared<RunnableFor>(nullptr, $2, nullptr, $4);
    }

conditional: if_closure { $$ = $1; };
    | if_else_closure { $$ = $1; }

if_else_closure:
    "if" exp "{" unit "}" "else" "{" unit "}" {
        $$ = std::make_shared<RunnableIf>(nullptr, $2, $4, $8);
    }
    | "if" assign ";" exp "{" unit "}" "else" "{" unit "}" {
        $$ = std::make_shared<RunnableIf>($2, $4, $6, $10);
    }

if_closure:
    "if" exp "{" unit "}" {
        $$ = std::make_shared<RunnableIf>(nullptr, $2, $4, nullptr);
    }
    | "if" assign ";" exp "{" unit "}" {
        $$ = std::make_shared<RunnableIf>($2, $4, $6, nullptr);
    }

assignment: assign ";" { $$ = $1; }

assign:
    "identifier" "=" exp {
        $$ = std::make_shared<RunnableAssign>($1, $3, driver);
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
