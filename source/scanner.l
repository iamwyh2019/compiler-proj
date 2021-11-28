%{
    #include <cstdio>
    #include "parser.tab.h"
%}
%option yylineno

letter_ [A-Za-z_]
digit [0-9]
octdigit [0-7]
hexdigit [0-9a-fA-F]

identifier {letter_}({letter_}|{digit})*

decnumber [1-9]{digit}*
octnumber 0{octdigit}*
hexnumber (0x|0X){hexdigit}+

%%
{identifier} {return IDENT;}
[\n\t\r]    {}
"+"     {return ADD;}
"-"     {return SUB;}
"*"     {return MUL;}
"/"     {return DIV;}
"<"     {return LE;}
"<="    {return LEQ;}
">"     {return GE;}
">="    {return GEQ;}
"=="    {return EQ;}
"!="    {return NEQ;}
"("     {return LPAREN;}
")"     {return RPAREN;}
"{"     {return LCURLY;}
"}"     {return RCURLY;}
"="     {return ASSIGN;}
if      {return IF;}
else    {return ELSE;}
continue  {return CONTINUE;}
break   {return BREAK;}
while   {return WHILE;}
return  {return RETURN;}
int     {return INT;}
const   {return CONST;}
";"     {return SEMI;}
"["     {return LBRAC;}
"]"     {return RBRAC;}
"&&"    {return AND;}
"||"    {return OR;}
"//".*$ {/* Single line comment */}
"/*"[^"*"]*(\*+[^"*/"][^"*"]*)*\*+"/"  { /* Multi-line comment. Copied from Zhenbang You */ }
%%

int main() {
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}