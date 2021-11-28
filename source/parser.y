%{
#include <cstdio>
int yyerror(const char *, ...);
extern int yylex();
extern int yyparse();    
%}

%token NUMBER
%token ADD SUB MUL DIV
%token IDENT

%%
identifier: IDENT {printf("Got an identifier!");}
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