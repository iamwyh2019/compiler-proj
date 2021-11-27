%{
    #include <cstdio>
%}
%option yylineno

letter_ [A-Za-z_]
digit [0-9]

identifier {letter_}({letter_}|{digit})*

%%
{identifier} {printf("Identifier!");}
%%

int main() {
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}