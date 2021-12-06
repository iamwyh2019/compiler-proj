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
    | VarDecl
    ;
ConstDecl:  CONST INT ConstDefList SEMI
    ;
ConstDefList:   ConstDef
    | ConstDefList COMMA ConstDef
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

        auto cid = new IntIdentToken(*(string*)$1, true); // const
        cid->setVal(V($3));
        nowScope->addToken(cid);
    }
    |   IDENT ArrayDim
    {
        cout << "New constant array with shape";
        for (auto s:*(vector<int>*)$2)
            cout << " " << s;
        cout << endl;
    }
    ;

ArrayDim:   ArrayDim LBRAC ConstExp RBRAC
    {
        $$ = $1;
        ((vector<int>*)$$)->push_back(V($3));
    }
    | LBRAC ConstExp RBRAC
    {
        $$ = new vector<int>;
        ((vector<int>*)$$)->push_back(V($2));
    }
    ;

ConstInitVal:   ConstExp {$$ = $1;}
    ;

VarDecl:    INT VarDefList SEMI
    ;
VarDefList: VarDef
    | VarDefList COMMA VarDef
    ;
VarDef: IDENT
    {
        auto name = *(string*)$1;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new IntIdentToken(*(string*)$1, false); // not const. Initially 0
        nowScope->addToken(cid);
    }
    | IDENT ASSIGN InitVal
    {
        auto name = *(string*)$1;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new IntIdentToken(*(string*)$1, false); // not const. Initially 0
        cid->setVal(V($3));
        nowScope->addToken(cid);
    }
    ;
InitVal:    Exp {$$ = $1;}
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

        $$ = cid;
    }
    ;
PrimaryExp: LPAREN Exp RPAREN {$$ = $2;}
    | LVal
    {
        auto cid = (IntIdentToken*)$1;
        $$ = new IntToken(cid->Val(), cid->isConst());
    }
    | NUMBER { $$ = new IntToken(V($1), true);}
    ;
UnaryExp:   PrimaryExp {$$ = $1;}
    | IDENT LPAREN [FuncParams] RPAREN
    | ADD UnaryExp {$$ = $2;}
    | SUB UnaryExp
    {
        auto cid = (IntToken*)$2;
        $$ = new IntToken(-cid->Val(), cid->isConst());
    }
    | NOT UnaryExp
    {
        auto cid = (IntToken*)$2;
        $$ = new IntToken(!cid->Val(), cid->isConst());
    }
    ;
FuncParams: Exp
    ;
MulExp:     UnaryExp {$$ = $1;}
    | MulExp MUL UnaryExp
    {
        auto c1 = (IntToken*)$1, c2 = (IntToken*)$3;
        $$ = new IntToken(c1->Val() * c2->Val(), *c1&*c2);
    }
    | MulExp DIV UnaryExp
    {
        auto c1 = (IntToken*)$1, c2 = (IntToken*)$3;
        $$ = new IntToken(c1->Val() / c2->Val(), *c1&*c2);
    }
    | MulExp MOD UnaryExp
    {
        auto c1 = (IntToken*)$1, c2 = (IntToken*)$3;
        $$ = new IntToken(c1->Val() % c2->Val(), *c1&*c2);
    }
    ;
AddExp:     MulExp {$$ = $1;}
    | AddExp ADD MulExp
    {
        auto c1 = (IntToken*)$1, c2 = (IntToken*)$3;
        $$ = new IntToken(c1->Val() + c2->Val(), *c1&*c2);
    }
    | AddExp SUB MulExp
    {
        auto c1 = (IntToken*)$1, c2 = (IntToken*)$3;
        $$ = new IntToken(c1->Val() - c2->Val(), *c1&*c2);
    }
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
ConstExp:   AddExp
    {
        auto cid = (IntToken*)$1;
        if (!cid->isConst()) {
            yyerror("Expecting constant expression.");
        }
        $$ = new int(cid->Val());
    }
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