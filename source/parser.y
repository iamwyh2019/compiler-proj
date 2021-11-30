%{
//Inspired by Zhenbang You
#define YYSTYPE void*

// Common headers
#include <cstdio>

// flex functions
void yyerror(const char *);
extern int yylex();
extern int yyparse();
%}

%token ADD SUB MUL DIV
%token IDENT
%token LPAREN RPAREN LCURLY RCURLY LBRAC RBRAC
%token INT CONST VOID
%token LE LEQ GE GEQ EQ NEQ AND OR NOT
%token IF ELSE WHILE BREAK CONTINUE RETURN
%token ASSIGN
%token SEMI COMMA PERIOD
%token NUMBER

%%
identifier: IDENT {printf("Identifier name %s\n", (char*)($1));}
    ;
%%

void yyerror(const char *s) {
    extern int yylineno;
    printf("Error! line %d: %s\n", yylineno, s);
}

int main() {
    printf("> ");
    yyparse();
    return 0;
}