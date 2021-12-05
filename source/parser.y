%{
//Inspired by Zhenbang You
#define YYSTYPE void*

// Common headers
#include <iostream>
#include <string>
using namespace std;

// flex functions
void yyerror(const char *);
extern int yylex();
extern int yyparse();

%}

%token ADD SUB MUL DIV MOD
%token IDENT
%token LPAREN RPAREN LCURLY RCURLY LBRAC RBRAC
%token INT CONST VOID
%token LE LEQ GE GEQ EQ NEQ AND OR NOT
%token IF ELSE WHILE BREAK CONTINUE RETURN
%token ASSIGN
%token SEMI COMMA PERIOD
%token NUMBER

%%
CompUnit:   Decl
    | CompUnit Decl;
Decl:       ConstDecl;
ConstDecl:  CONST INT ConstDef SEMI
    ;
ConstDef:   IDENT ASSIGN ConstInitVal
    {
        cout << "Getting a const with name " << (char*)$1 << " and value " << *(int*)$3 << endl;
    }
ConstInitVal:   ConstExp;

Exp:    AddExp;
Cond:   LOrExp;
LVal:   IDENT;
PrimaryExp: LPAREN Exp RPAREN
    | LVal
    | NUMBER
    ;
UnaryExp:   PrimaryExp
    | IDENT LPAREN [FuncParams] RPAREN
    | ADD UnaryExp
    | SUB UnaryExp
    | NOT UnaryExp
    ;
FuncParams: Exp;
MulExp:     UnaryExp
    | MulExp MUL UnaryExp
    | MulExp DIV UnaryExp
    | MulExp MOD UnaryExp
    ;
AddExp:     MulExp
    | AddExp ADD MulExp
    | AddExp SUB MulExp
    ;
RelExp:     AddExp
    | RelExp LE AddExp
    | RelExp GE AddExp
    | RelExp LEQ AddExp
    | RelExp GEQ AddExp
    ;
EqExp:      RelExp
    | EqExp EQ RelExp
    | EqExp NEQ RelExp
    ;
LAndExp:    EqExp
    | LAndExp AND EqExp
    ;
LOrExp:     LAndExp
    | LOrExp OR LAndExp
    ;
ConstExp:   AddExp
    ;
%%

void yyerror(const char *s) {
    extern int yylineno;
    cout << "Error! line " << yylineno << ": " << s << endl;;
}

int main() {
    ios::sync_with_stdio(false);
    yyparse();
    return 0;
}