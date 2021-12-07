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
extern const int INTSIZE;

Scope globalScope;
Scope *nowScope = &globalScope;

auto arrOp_assign = ArrayOperator();
auto arrOp_access = ArrayOperator();

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

        out << cid->Declare() << endl;

        arrOp_assign.setTarget(cid);
    }
    ASSIGN ConstArrayVal
    {
        string &arrName = arrOp_assign.name();
        int n = arrOp_assign.size();
        for (int i = 0; i < n; ++i)
            out << arrName << "[" << i*INTSIZE << "] = " << arrOp_assign[i] << endl;
    }
    ;

ConstArrayVal:  ConstExp
    {
        if (!arrOp_assign.addOne(V($1)))
            yyerror("Array out of bound.");
    }
    | LCURLY RCURLY
    {
        if (!arrOp_assign.jumpOne())
            yyerror("Nested list too deep.");
    }
    | LCURLY
    {
        if (!arrOp_assign.moveDown())
            yyerror("Nested list too deep.");
    }
    ConstArrayVals RCURLY
    {
        if (!arrOp_assign.moveUp())
            yyerror("Unknown error in \"}\"");
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

        auto cid = new IntIdentToken(name, false); // not const. Initially 0
        nowScope->addToken(cid);

        out << cid->Declare() << endl;
        out << cid->getName() << " = 0" << endl;
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
    | IDENT ArrayDim
    {
        auto name = *(string*)$1;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new ArrayIdentToken(name, false); // not const. Initially 0
        cid->setShape(*(vector<int>*)$2);
        nowScope->addToken(cid);

        int size = cid->size();
        string &arrName = cid->getName();
        out << cid->Declare() << endl;
        for (int i = 0; i < size; ++i)
            out << arrName << "[" << i*4 << "] = 0" << endl;
    }
    | IDENT ArrayDim
    {
        auto name = *(string*)$1;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new ArrayIdentToken(name, false); // not const. Initially 0
        cid->setShape(*(vector<int>*)$2);
        nowScope->addToken(cid);

        out << cid->Declare() << endl;

        arrOp_assign.setTarget(cid);
    }
    ASSIGN VarArrVal
    {
        string &arrName = arrOp_assign.name();
        int n = arrOp_assign.size();
        for (int i = 0; i < n; ++i) {
            auto ele = arrOp_assign(i);
            out << arrName << "[" << i*4 << "] = ";

            if (ele == nullptr)
                out << 0 << endl;
            else if (ele->isConst())
                out << ele->Val() << endl;
            else
                out << ele->getName() << endl;
        }
    }
    ;

VarArrVal:  Exp
    {
        if (!arrOp_assign.addOne((IntIdentToken*)$1))
            yyerror("Array out of bound.");
    }
    | LCURLY RCURLY
    {
        if (!arrOp_assign.jumpOne())
            yyerror("Nested list too deep.");
    }
    | LCURLY
    {
        if (!arrOp_assign.moveDown())
            yyerror("Nested list too deep.");
    }
    VarArrVals RCURLY
    {
        if (!arrOp_assign.moveUp())
            yyerror("Unknown error in \"}\"");
    }
    ;

VarArrVals: VarArrVals COMMA VarArrVal
    | VarArrVal
    ;

InitVal:    Exp {$$ = $1;}
    ;

Exp:    AddExp;
Cond:   LOrExp;
LVal:   IDENT
    {
        auto name = *(string*)$1;
        auto cid = (IdentToken*)nowScope->findAll(name);

        if (cid == nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" undefined in this scope.";
            yyerror(errmsg);
        }

        if (cid->Type() != IntType)
            yyerror("Int identifier required.");
        cid = (IntIdentToken*)cid;

        $$ = cid;
    }
    | IDENT ArrayIndices
    {
        auto name = *(string*)$1;
        auto cid = (IdentToken*)nowScope->findAll(name);

        if (cid == nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" undefined in this scope.";
            yyerror(errmsg);
        }

        if (cid->Type() != ArrayType)
            yyerror("Array identifier required.");
        auto arrcid = (ArrayIdentToken*)cid;
        arrOp_access.setTarget(arrcid);

        auto indices = *((vector<IntIdentToken*>*)$2);
        if (arrOp_access.dim() != indices.size())
            yyerror("Incompatible dimension.");
        
        bool allConst = true;
        for (auto &ele: indices)
            if (!ele->isConst()) {
                allConst = false;
                break;
            }
        
        int offset = arrOp_access.getOffset(indices); // The constant part of the indices
        if (offset == -1)
            yyerror("Index out of bound.");
        
        if (cid->isConst()) {
            if (!allConst)
                yyerror("Constant expression required for index.");
            $$ = new IntIdentToken(arrOp_access[offset]);
        }
        else {
            auto newcid = new IntIdentToken(); // The value
            out << newcid->Declare() << endl;

            if (allConst) {
                out << newcid->getName() << " = " << cid->getName() << "[" << offset*INTSIZE << "]" << endl;
            }
            else {
                auto idxVar = new IntIdentToken(); // The int token for the index
                out << idxVar->Declare() << endl;
                out << idxVar->getName() << " = " << offset*INTSIZE << endl;
                string &idxName = idxVar->getName();

                int idxOffset, dims = indices.size();
                for (int i = 0; i < dims; ++i) {
                    if (indices[i]->isConst()) continue;

                    auto tmp = new IntIdentToken(); // The temp var for multiplication
                    out << tmp->Declare() << endl;
                    idxOffset = arrOp_access.ndim(i) * 4;
                    out << tmp->getName() << " = " << indices[i]->getName() << " * " << idxOffset << endl;
                    out << idxName << " = " << idxName << " + " << tmp->getName() << endl;
                }
                out << newcid->getName() << " = " << cid->getName() << "[" << idxVar->getName() << "]" << endl;
            }

            $$ = newcid;
        }
    }
    ;

ArrayIndices:   ArrayIndex
    {
        auto indices = new vector<IntIdentToken*>();
        indices->push_back((IntIdentToken*)$1);
        $$ = indices;
    }
    | ArrayIndices ArrayIndex
    {
        $$ = $1;
        ((vector<IntIdentToken*>*)$$)->push_back((IntIdentToken*)$2);
    }
    ;

ArrayIndex: LBRAC Exp RBRAC
    {
        auto cid = (IdentToken*)$2;
        if (cid->Type() != IntType)
            yyerror("Integer index required.");
        $$ = cid;        
    }

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
            auto newcid = new IntIdentToken();
            out << newcid->Declare() << endl;
            out << newcid->getName() << " = -" << cid->getName() << endl;
            $$ = newcid;
        }
    }
    | NOT UnaryExp
    {
        auto cid = (IntIdentToken*)$2;
        if (cid->isConst())
            $$ = new IntIdentToken(!cid->Val());
        else {
            auto newcid = new IntIdentToken(); // A temporary var
            out << newcid->Declare() << endl;
            out << newcid->getName() << " = !" << cid->getName() << endl;
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
            auto newcid = new IntIdentToken(); // A tmp var
            out << newcid->Declare() << endl;
            out << newcid->getName() << " = " << c1->getName() << " * " << c2->getName() << endl;
            $$ = newcid;
        }
    }
    | MulExp DIV UnaryExp
    {
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            if (c2->Val() == 0)
                yyerror("devided by zero!");
            $$ = new IntIdentToken(c1->Val() / c2->Val());
        }
        else {
            auto newcid = new IntIdentToken(); // A tmp var
            out << newcid->Declare() << endl;
            out << newcid->getName() << " = " << c1->getName() << " / " << c2->getName() << endl;
            $$ = newcid;
        }
    }
    | MulExp MOD UnaryExp
    {
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            if (c2->Val() == 0)
                yyerror("devided by zero!");
            $$ = new IntIdentToken(c1->Val() % c2->Val());
        }
        else {
            auto newcid = new IntIdentToken();
            out << newcid->Declare() << endl;
            out << newcid->getName() << " = " << c1->getName() << " % " << c2->getName() << endl;
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
            auto newcid = new IntIdentToken();
            out << newcid->Declare() << endl;
            out << newcid->getName() << " = " << c1->getName() << " + " << c2->getName() << endl;
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
            auto newcid = new IntIdentToken();
            out << newcid->Declare() << endl;
            out << newcid->getName() << " = " << c1->getName() << " - " << c2->getName() << endl;
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