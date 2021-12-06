%{
//Inspired by Zhenbang You
#define YYSTYPE void*

// shorthand for taking int value from a void*
#define V(p) (*((int*)(p)))

// Common headers
#include <iostream>
#include <fstream>
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

auto arrOp = ArrayOperator();

// Currently print to the screen. Will change to files.
ostream &out = cout;

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

        auto cid = new IntIdentToken(name, true); // const
        cid->setVal(V($3));
        nowScope->addToken(cid);
        
    }
    |   IDENT ArrayDim
    {
        auto name = *(string*)$1;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new ArrayIdentToken(name, true); // const
        cid->setShape(*(vector<int>*)$2);
        nowScope->addToken(cid);

        arrOp.setTarget(cid);
    }
    ASSIGN ConstArrayVal
    ;

ConstArrayVal:  ConstExp
    {
        if (!arrOp.addOne(V($1)))
            yyerror("Array out of bound.");
    }
    | LCURLY RCURLY
    {
        if (!arrOp.jumpOne())
            yyerror("Nested list too deep.");
    }
    | LCURLY
    {
        if (!arrOp.moveDown())
            yyerror("Nested list too deep.");
    }
    ConstArrayVals RCURLY
    {
        if (!arrOp.moveUp())
            yyerror("Unknown error in }");
    }
    ;

ConstArrayVals: ConstArrayVals COMMA ConstArrayVal
    | ConstArrayVal
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

        out << cid->Declare() << endl;
    }
    | IDENT ASSIGN InitVal
    {
        auto name = *(string*)$1;
        auto oldcid = nowScope->findOne(name);
        auto initRes = (IntIdentToken*)$3;

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        IntIdentToken *cid;

        if (!initRes->isTmp()) { // It's either a constant or a declared variable, need to declare a new one
            cid = new IntIdentToken(name, false); // not const
            out << cid->Declare() << endl;
            out << cid->getName() << "=" << initRes->getName() << endl;
        }
        else { // It's a temporary variable, just use it
            cid = initRes;
            cid->setName(name);
            cid->setTmp(false);
        }
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
    | LVal {$$ = $1;}
    | NUMBER { $$ = new IntIdentToken(V($1));}
    ;
UnaryExp:   PrimaryExp {$$ = $1;}
    | IDENT LPAREN [FuncParams] RPAREN
    | ADD UnaryExp {$$ = $2;}
    | SUB UnaryExp
    {
        auto cid = (IntIdentToken*)$2;
        if (cid->isConst())
            $$ = new IntIdentToken(-cid->Val());
        else {
            auto newcid = new IntIdentToken(-cid->Val(), false, true);
            out << newcid->Declare() << endl;
            out << newcid->getName() << "=-" << cid->getName() << endl;
            $$ = newcid;
        }
    }
    | NOT UnaryExp
    {
        auto cid = (IntIdentToken*)$2;
        if (cid->isConst())
            $$ = new IntIdentToken(!cid->Val());
        else {
            auto newcid = new IntIdentToken(!cid->Val(), false, true);
            out << newcid->Declare() << endl;
            out << newcid->getName() << "=!" << cid->getName() << endl;
            $$ = newcid;
        }
    }
    ;
FuncParams: Exp
    ;
MulExp:     UnaryExp {$$ = $1;}
    | MulExp MUL UnaryExp
    {
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            $$ = new IntIdentToken(c1->Val() * c2->Val());
        }
        else {
            auto newcid = new IntIdentToken(c1->Val() * c2->Val(), false, true); // A tmp var
            out << newcid->Declare() << endl;
            out << newcid->getName() << "=" << c1->getName() << "*" << c2->getName() << endl;
            $$ = newcid;
        }
    }
    | MulExp DIV UnaryExp
    {
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            $$ = new IntIdentToken(c1->Val() / c2->Val());
        }
        else {
            auto newcid = new IntIdentToken(c1->Val() / c2->Val(), false, true); // A tmp var
            out << newcid->Declare() << endl;
            out << newcid->getName() << "=" << c1->getName() << "/" << c2->getName() << endl;
            $$ = newcid;
        }
    }
    | MulExp MOD UnaryExp
    {
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            $$ = new IntIdentToken(c1->Val() % c2->Val());
        }
        else {
            auto newcid = new IntIdentToken(c1->Val() % c2->Val(), false, true);
            out << newcid->Declare() << endl;
            out << newcid->getName() << "=" << c1->getName() << "%" << c2->getName() << endl;
            $$ = newcid;
        }
    }
    ;
AddExp:     MulExp {$$ = $1;}
    | AddExp ADD MulExp
    {
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            $$ = new IntIdentToken(c1->Val() + c2->Val());
        }
        else {
            auto newcid = new IntIdentToken(c1->Val() + c2->Val(), false, true);
            out << newcid->Declare() << endl;
            out << newcid->getName() << "=" << c1->getName() << "+" << c2->getName() << endl;
            $$ = newcid;
        }
    }
    | AddExp SUB MulExp
    {
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            $$ = new IntIdentToken(c1->Val() - c2->Val());
        }
        else {
            auto newcid = new IntIdentToken(c1->Val() - c2->Val(), false, true);
            out << newcid->Declare() << endl;
            out << newcid->getName() << "=" << c1->getName() << "-" << c2->getName() << endl;
            $$ = newcid;
        }
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
        auto cid = (IntIdentToken*)$1;
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