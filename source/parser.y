%{
//Inspired by Zhenbang You
#define YYSTYPE void*

// shorthand for taking int value from a void*
#define V(p) (*((int*)(p)))

// Common headers
#include <iostream>
#include <string>
#include <cstdlib>
using namespace std;

// Token class
#include "tokenclass.h"

// flex functions
void yyerror(const char *);
void yyerror(const string&);
extern int yylex();
extern int yyparse();

Scope globalScope;
Scope *nowScope = &globalScope;

%}

%token ADD SUB MUL DIV MOD
%token IDENT
%token LPAREN RPAREN LCURLY RCURLY LBRAC RBRAC
%token INT CONST VOID
%token LE LEQ GE GEQ EQ NEQ AND OR NOT
%token IF ELSE WHILE BREAK CONT RETURN
%token ASSIGN
%token SEMI COMMA PERIOD
%token NUMBER

%%
CompUnit:   Decl
    | CompUnit Decl;
Decl:       ConstDecl
    {
        auto cid = (IntIdentToken*)$1;
        cout << "Constant with name " << cid->Name() << " and value " << cid->Val() << endl;
    }
    ;
ConstDecl:  CONST INT ConstDef SEMI {$$ = $3;}
    ;
ConstDef:   IDENT ASSIGN ConstInitVal
    {
        auto name = *(string*)$1;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new IntIdentToken(*(string*)$1, true);
        cid->setVal(V($3));
        nowScope->addToken(cid);
        $$ = cid;
    }
ConstInitVal:   ConstExp {$$ = $1;}
    ;

Exp:    AddExp;
Cond:   LOrExp;
LVal:   IDENT
    {
        auto name = *(string*)$1;
        auto cid = (IntIdentToken*)nowScope->findAll(name);
        
        if (cid == nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" undefined in this scope.";
            yyerror(errmsg);
        }

        $$ = new int(cid->Val());
    }
    ;
PrimaryExp: LPAREN Exp RPAREN {$$ = $2;}
    | LVal {$$ = $1;}
    | NUMBER { $$ = $1;}
    ;
UnaryExp:   PrimaryExp {$$ = $1;}
    | IDENT LPAREN [FuncParams] RPAREN
    | ADD UnaryExp {$$ = $2;}
    | SUB UnaryExp {$$ = new int(-V($2));}
    | NOT UnaryExp {$$ = new int(!V($2));}
    ;
FuncParams: Exp
    ;
MulExp:     UnaryExp {$$ = $1;}
    | MulExp MUL UnaryExp {$$ = new int(V($1)*V($3));}
    | MulExp DIV UnaryExp {$$ = new int(V($1)/V($3));}
    | MulExp MOD UnaryExp {$$ = new int(V($1)%V($3));}
    ;
AddExp:     MulExp {$$ = $1;}
    | AddExp ADD MulExp {$$ = new int(V($1)+V($3));}
    | AddExp SUB MulExp {$$ = new int(V($1)-V($3));}
    ;
RelExp:     AddExp {$$ = $1;}
    | RelExp LE AddExp {$$ = new bool(V($1)<V($3));}
    | RelExp GE AddExp {$$ = new bool(V($1)>V($3));}
    | RelExp LEQ AddExp {$$ = new bool(V($1)<=V($3));}
    | RelExp GEQ AddExp {$$ = new bool(V($1)>=V($3));}
    ;
EqExp:      RelExp {$$ = $1;}
    | EqExp EQ RelExp {$$ = new bool(V($1)==V($3));}
    | EqExp NEQ RelExp {$$ = new bool(V($1)!=V($3));}
    ;
LAndExp:    EqExp {$$ = $1;}
    | LAndExp AND EqExp {$$ = new bool(V($1)&&V($3));}
    ;
LOrExp:     LAndExp {$$ = $1;}
    | LOrExp OR LAndExp {$$ = new bool(V($1)||V($3));}
    ;
ConstExp:   AddExp {$$ = $1;}
    ;
%%

void yyerror(const char *s) {
    extern int yylineno, charNum;
    cout << "Line " << yylineno << "," << charNum << ": " << s << endl;
    exit(1);
}

void yyerror(const string &s) {
    yyerror(s.c_str());
}

int main() {
    ios::sync_with_stdio(false);
    yyparse();
    return 0;
}