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

FuncIdentToken *nowFunc = nullptr;

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
    | CompUnit Decl
    | FuncDef
    | CompUnit FuncDef
    ;
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
        cid->setShape(*(deque<int>*)$2);
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
        ((deque<int>*)$$)->push_back(V($3));
    }
    | LBRAC ConstExp RBRAC
    {
        $$ = new deque<int>;
        ((deque<int>*)$$)->push_back(V($2));
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
            out << cid->getName() << " = " << initRes->getName() << endl;
        }
        else { // It's a temporary variable, just use it
            cid = initRes;
            cid->setVarName(name);
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
        cid->setShape(*(deque<int>*)$2);
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
        cid->setShape(*(deque<int>*)$2);
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

InitVal:    Exp
    {
        auto cid = (IdentToken*)$1;
        if (cid->Type() != IntType)
            yyerror("Integer initial value required.");
        $$ = cid;
    }
    ;

FuncDef:    INT IDENT LPAREN
    {
        auto name = *(string*)$2;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new FuncIdentToken(RetInt, name);
        nowScope->addToken(cid);
        nowFunc = cid;
        $$ = cid;

        auto nextScope = new Scope(nowScope, true); // is a parameter scope. Inspired by Zhenbang You
        nowScope = nextScope;
    }
    FuncFParams RPAREN
    {
        auto cid = (FuncIdentToken*)$4;
        cid->setNParams(V($5));
        out << cid->Declare() << endl;
        $$ = cid;
    }
    Block
    {
        auto faScope = nowScope->Parent();
        delete nowScope;
        nowScope = faScope;
        out << "return 0" << endl;
        out << "end " << ((FuncIdentToken*)$4)->getName() << endl;
        nowFunc = nullptr;
    }
    | INT IDENT LPAREN RPAREN
    {
        auto name = *(string*)$2;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new FuncIdentToken(RetInt, name);
        out << cid->Declare() << endl;
        nowScope->addToken(cid);
        nowFunc = cid;
        $$ = cid;
    }
    Block
    {
        out << "return 0" << endl;
        out << "end " << ((FuncIdentToken*)$5)->getName() << endl;
        nowFunc = nullptr;
    }
    | VOID IDENT LPAREN
    {
        auto name = *(string*)$2;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new FuncIdentToken(RetVoid, name);
        nowScope->addToken(cid);
        nowFunc = cid;
        $$ = cid;

        auto nextScope = new Scope(nowScope, true); // is a parameter scope. Inspired by Zhenbang You
        nowScope = nextScope;
    }
    FuncFParams RPAREN
    {
        auto cid = (FuncIdentToken*)$4;
        cid->setNParams(V($5));
        out << cid->Declare() << endl;
        $$ = cid;
    }
    Block
    {
        auto faScope = nowScope->Parent();
        delete nowScope;
        nowScope = faScope;
        out << "return" << endl;
        out << "end " << ((FuncIdentToken*)$4)->getName() << endl;
        nowFunc = nullptr;
    }
    | VOID IDENT LPAREN RPAREN
    {
        auto name = *(string*)$2;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" already defined in this scope.";
            yyerror(errmsg);
        }

        auto cid = new FuncIdentToken(RetVoid, name);
        out << cid->Declare() << endl;
        nowScope->addToken(cid);
        nowFunc = cid;
        $$ = cid;
    }
    Block
    {
        out << "return" << endl;
        out << "end " << ((FuncIdentToken*)$5)->getName() << endl;
        nowFunc = nullptr;
    }
    ;

FuncFParams:    FuncFParams COMMA FuncFParam
    {
        ++V($1);
        $$ = $1;
    }
    | FuncFParam
    {
        $$ = new int(1);
    }
    ;

FuncFParam: INT IDENT
    {
        auto name = *(string*)$2;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) { // Declared the same param
            string errmsg = "Parameter \"";
            errmsg += name;
            errmsg += "\" already defined.";
            yyerror(errmsg);
        }

        auto cid = new IntIdentToken(name, false, false, true);
        nowScope->addToken(cid);
        $$ = cid;
    }
    | INT IDENT LBRAC RBRAC
    {
        auto name = *(string*)$2;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) { // Declared the same param
            string errmsg = "Parameter \"";
            errmsg += name;
            errmsg += "\" already defined.";
            yyerror(errmsg);
        }

        auto cid = new ArrayIdentToken(name, false, false, true);
        deque<int> shape(1,-1);
        cid->setShape(shape);

        nowScope->addToken(cid);
        $$ = cid;
    }
    | INT IDENT LBRAC RBRAC ArrayDim
    {
        auto name = *(string*)$2;
        auto oldcid = nowScope->findOne(name);

        if (oldcid != nullptr) { // Declared the same param
            string errmsg = "Parameter \"";
            errmsg += name;
            errmsg += "\" already defined.";
            yyerror(errmsg);
        }

        auto cid = new ArrayIdentToken(name, false, false, true);
        auto shape = *(deque<int>*)$5;
        shape.push_front(-1);
        cid->setShape(shape);

        nowScope->addToken(cid);
        $$ = cid;
    }
    ;

Block:  LCURLY
    {
        auto nextScope = new Scope(nowScope);
        nowScope = nextScope;
    }
    BlockItems RCURLY
    {
        auto faScope = nowScope->Parent();
        delete nowScope;
        nowScope = faScope;
    }
    | LCURLY RCURLY
    ;

BlockItems: BlockItems BlockItem
    | BlockItem
    ;

BlockItem:  Decl
    | Stmt
    ;

Stmt:   LVal ASSIGN Exp SEMI
    {
        auto lval = (IntIdentToken*)$1,
            rval = (IntIdentToken*)$3;

        if (lval->isConst())
            yyerror("Cannot assign values to a constant.");
        
        out << lval->getName() << " = " << rval->getName() << endl;
    }
    | Exp SEMI
    | SEMI
    | Block
    | RETURN SEMI
    {
        if (nowFunc == nullptr)
            yyerror("Not in a function.");
        if (nowFunc->retType() != RetVoid)
            yyerror("This function does not return void.");
        out << "return" << endl;
    }
    | RETURN Exp SEMI
    {
        if (nowFunc == nullptr)
            yyerror("Not in a function.");
        if (nowFunc->retType() != RetInt)
            yyerror("This function does not return int.");
        auto cid = (IntIdentToken*)$2;
        out << "return " << cid->getName() << endl;
    }
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

        auto indices = *((deque<IntIdentToken*>*)$2);
        if (arrOp_access.dim() < indices.size())
            yyerror("Dimension overflow.");
        
        bool allConst = true;
        bool downToEle = (arrOp_access.dim() == indices.size());
        for (auto &ele: indices)
            if (!ele->isConst()) {
                allConst = false;
                break;
            }
        
        int offset = arrOp_access.getOffset(indices); // The constant part of the indices
        if (offset == -1)
            yyerror("Index out of bound.");
        
        if (cid->isConst() && allConst && downToEle) {
            $$ = new IntIdentToken(arrOp_access[offset]); // Accessing a constant value
        }
        else {
            IntIdentToken *newcid; // The value

            if (allConst) {
                newcid = new IntIdentToken(cid->getName(), to_string(offset*INTSIZE));
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
                newcid = new IntIdentToken(cid->getName(), idxVar->getName());
            }

            $$ = newcid;
        }
    }
    ;

ArrayIndices:   ArrayIndex
    {
        auto indices = new deque<IntIdentToken*>();
        indices->push_back((IntIdentToken*)$1);
        $$ = indices;
    }
    | ArrayIndices ArrayIndex
    {
        $$ = $1;
        ((deque<IntIdentToken*>*)$$)->push_back((IntIdentToken*)$2);
    }
    ;

ArrayIndex: LBRAC Exp RBRAC
    {
        auto cid = (IdentToken*)$2;
        if (cid->Type() != IntType)
            yyerror("Integer index required.");
        $$ = cid;        
    }
    ;

FuncRParams:    FuncRParams COMMA Exp
    {
        auto cid = (vector<IdentToken*>*)$1;
        cid->push_back((IdentToken*)$3);
        $$ = cid;
    }
    | Exp
    {
        auto cid = new vector<IdentToken*>;
        cid->push_back((IdentToken*)$1);
        $$ = cid;
    }
    ;

PrimaryExp: LPAREN Exp RPAREN {$$ = $2;}
    | LVal
    {
        auto cid = (IntIdentToken*)$1;
        if (cid->isSlice()) {
            auto newcid = new IntIdentToken();
            out << newcid->getName() << " = " << cid->getName() << endl;
            cid = newcid;
        }
        $$ = cid;
    }
    | NUMBER { $$ = new IntIdentToken(V($1));}
    ;
UnaryExp:   PrimaryExp {$$ = $1;}
    | IDENT LPAREN FuncRParams RPAREN
    {
        auto name = *(string*)$1;
        auto cid = (IdentToken*)nowScope->findAll(name);

        if (cid == nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" undefined in this scope.";
            yyerror(errmsg);
        }

        if (cid->Type() != FuncType) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" is not a function.";
            yyerror(errmsg);
        }

        auto func = (FuncIdentToken*)cid;
        auto params = *(vector<IdentToken*>*)$3;
        int nparam = params.size();

        if (func->nParams() != nparam){
            string errmsg = to_string(func->nParams());
            errmsg += " params expected, but ";
            errmsg += to_string(nparam);
            errmsg += " get.";
            yyerror(errmsg);
        }

        for (int i = 0; i < nparam; ++i) {
            auto param = params[i];
            out << "param " << param->getName() << endl;
        }

        if (func->retType() == RetInt) {
            auto cc = new IntIdentToken();
            out << cc->Declare() << endl;
            out << cc->getName() << " = call " << func->getName() << endl;
            $$ = cc;
        }
        else if (func->retType() == RetVoid) {
            out << "call " << func->getName() << endl;
            $$ = new VoidToken();
        }
        else {
            yyerror("Unknown return type.");
        }
    }
    | IDENT LPAREN RPAREN
    {
        auto name = *(string*)$1;
        auto cid = (IdentToken*)nowScope->findAll(name);

        if (cid == nullptr) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" undefined in this scope.";
            yyerror(errmsg);
        }

        if (cid->Type() != FuncType) {
            string errmsg = "\"";
            errmsg += name;
            errmsg += "\" is not a function.";
            yyerror(errmsg);
        }

        auto func = (FuncIdentToken*)cid;
        if (func->nParams() != 0){
            string errmsg = to_string(func->nParams());
            errmsg += " params expected, but 0 get.";
            yyerror(errmsg);
        }

        if (func->retType() == RetInt) {
            auto cc = new IntIdentToken();
            out << cc->Declare() << endl;
            out << cc->getName() << " = call " << func->getName() << endl;
            $$ = cc;
        }
        else if (func->retType() == RetVoid) {
            out << "call " << func->getName() << endl;
            $$ = new VoidToken();
        }
        else {
            yyerror("Unknown return type.");
        }
    }
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