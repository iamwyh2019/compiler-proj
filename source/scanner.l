%{
// Inspired by Zhenbang You
#define YYSTYPE void*
// Common headers
#include <iostream>
#include <string>
using namespace std;
// Token table
#include "parser.tab.h"
// Token class
#include "tokenclass.h"

int charNum = 1;
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
[\040\t]    {charNum += yyleng;}
[\n\r]  {charNum = 1;}
if      {charNum += yyleng; return IF;}
else    {charNum += yyleng; return ELSE;}
continue  {charNum += yyleng; return CONT;}
break   {charNum += yyleng; return BREAK;}
while   {charNum += yyleng; return WHILE;}
return  {charNum += yyleng; return RETURN;}
int     {charNum += yyleng; return INT;}
void    {charNum += yyleng; return VOID;}
const   {charNum += yyleng; return CONST;}
"+"     {++charNum; return ADD;}
"-"     {++charNum; return SUB;}
"*"     {++charNum; return MUL;}
"/"     {++charNum; return DIV;}
"<"     {++charNum; return LE;}
"<="    {charNum += 2; return LEQ;}
">"     {++charNum; return GE;}
">="    {charNum += 2; return GEQ;}
"=="    {charNum += 2; return EQ;}
"!="    {charNum += 2; return NEQ;}
"("     {++charNum; return LPAREN;}
")"     {++charNum; return RPAREN;}
"{"     {++charNum; return LCURLY;}
"}"     {++charNum; return RCURLY;}
"="     {++charNum; return ASSIGN;}
";"     {++charNum; return SEMI;}
"["     {++charNum; return LBRAC;}
"]"     {++charNum; return RBRAC;}
"&&"    {charNum += 2; return AND;}
"||"    {charNum += 2; return OR;}
","     {++charNum; return COMMA;}
"."     {++charNum; return PERIOD;}
"!"     {++charNum; return NOT;}
"%"     {++charNum; return MOD;}
{decnumber} {
    yylval = new int(strtol(yytext, nullptr, 10));
    charNum += yyleng;
    return NUMBER;
}
{octnumber} {
    yylval = new int(strtol(yytext, nullptr, 8));
    charNum += yyleng;
    return NUMBER;
}
{hexnumber} {
    yylval = new int(strtol(yytext, nullptr, 16));
    charNum += yyleng;
    return NUMBER;
}
{identifier} {
    yylval = new string(yytext);
    charNum += yyleng;
    return IDENT;
}

"//".*$ {/* Single line comment */}
"/*"[^"*"]*(\*+[^"*/"][^"*"]*)*\*+"/"  { /* Multi-line comment. Copied from Zhenbang You */ }
%%

int yywrap() {
    return 1;
}