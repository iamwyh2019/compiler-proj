%{
    #include <cstdio>
    #include "parser.tab.h"
%}
%option yylineno

letter_ [A-Za-z_]
digit [0-9]

identifier {letter_}({letter_}|{digit})*

%%
{digit} {printf("A number!"); return NUMBER;}
{identifier} {printf("Identifier!"); return IDENT;}
%%

int main() {
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}