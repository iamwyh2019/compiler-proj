%{
// Inspired by Zhenbang You
#define YYSTYPE void*
// Common headers
#include <cstdio>
#include <cstring>
// Token table
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
[\n\t\r]    {}
if      {return IF;}
else    {return ELSE;}
continue  {return CONTINUE;}
break   {return BREAK;}
while   {return WHILE;}
return  {return RETURN;}
int     {return INT;}
const   {return CONST;}
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
";"     {return SEMI;}
"["     {return LBRAC;}
"]"     {return RBRAC;}
"&&"    {return AND;}
"||"    {return OR;}
","     {return COMMA;}
"."     {return PERIOD;}
"!"     {return NOT;}
{decnumber}|{octnumber}|{hexnumber} {
    int *val_ptr = new int;
    sscanf(yytext, "%i", val_ptr);
    yylval = val_ptr;
    return NUMBER;
}
{identifier} {
    char *name = new char[yyleng+1];
    strncpy(name, yytext, yyleng);
    yylval = name;
    return IDENT;
}

"//".*$ {/* Single line comment */}
"/*"[^"*"]*(\*+[^"*/"][^"*"]*)*\*+"/"  { /* Multi-line comment. Copied from Zhenbang You */ }
%%

int yywrap() {
    return 1;
}