%{
#include <cstdio>
int yyerror(const char *, ...);
extern int yylex();
extern int yyparse();    
%}

%token ADD SUB MUL DIV
%token IDENT
%token LPAREN RPAREN LCURLY RCURLY LBRAC RBRAC
%token INT CONST VOID
%token LE LEQ GE GEQ EQ NEQ AND OR
%token IF ELSE WHILE BREAK CONTINUE RETURN
%token ASSIGN
%token SEMI

%%
identifier: IDENT
    ;
%%

void yyerror(const char *s, ...) {
    extern int yylineno;
    printf("Error on line %d: %s\n", yylineno, s);
}

int main() {
    printf("> ");
    yyparse();
    return 0;
}