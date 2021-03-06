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
extern int yylineno, charNum;
extern FILE *yyin;

Scope globalScope;
Scope *nowScope = &globalScope;

auto arrOp_assign = ArrayOperator();
auto arrOp_access = ArrayOperator();

FuncIdentToken *nowFunc = nullptr;

auto parser = Parser();

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

        parser.addDecl(cid, nowFunc);

        arrOp_assign.setTarget(cid);
    }
    ASSIGN ConstArrayVal
    {
        string &arrName = arrOp_assign.name();
        int n = arrOp_assign.size();
        for (int i = 0; i < n; ++i)
            parser.addStmt(arrName + '[' + to_string(i*INTSIZE) 
                            + "] = " + to_string(arrOp_assign[i]));
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

        parser.addDecl(cid, nowFunc);
        parser.addStmt(cid->getName() + " = 0");
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
            parser.addDecl(cid, nowFunc);
            parser.addStmt(cid->getName() + " = " + initRes->getName());
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

        parser.addDecl(cid->Declare(), nowFunc);
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

        parser.addDecl("@" + cid->Declare(), nowFunc);

        arrOp_assign.setTarget(cid);
    }
    ASSIGN VarArrVal
    {
        string &arrName = arrOp_assign.name();

        int ntokens = arrOp_assign.nTokens();
        for (int i = 0; i < ntokens; ++i) {
            auto &p = arrOp_assign(i);
            string stmt = arrName + "[" + to_string(p.first*4) + "] = " + p.second->getName();
            parser.addStmt(stmt);
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
        // Function declaration is deemed as a statement
        parser.addStmt(cid);
        $$ = cid;
    }
    Block
    {
        auto faScope = nowScope->Parent();
        delete nowScope;
        nowScope = faScope;
        parser.addStmt("return 0",1);
        parser.addStmt("end " + ((FuncIdentToken*)$4)->getName());
        nowFunc = nullptr;
        IdentToken::resetParamCount();
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
        parser.addStmt(cid);
        nowScope->addToken(cid);
        nowFunc = cid;
        $$ = cid;
    }
    Block
    {
        parser.addStmt("return 0",1);
        parser.addStmt("end " + ((FuncIdentToken*)$5)->getName());
        nowFunc = nullptr;
        IdentToken::resetParamCount();
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
        parser.addStmt(cid);
        $$ = cid;
    }
    Block
    {
        auto faScope = nowScope->Parent();
        delete nowScope;
        nowScope = faScope;
        parser.addStmt("return",1);
        parser.addStmt("end " + ((FuncIdentToken*)$4)->getName());
        nowFunc = nullptr;
        IdentToken::resetParamCount();
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
        parser.addStmt(cid);
        nowScope->addToken(cid);
        nowFunc = cid;
        $$ = cid;
    }
    Block
    {
        parser.addStmt("return",1);
        parser.addStmt("end " + ((FuncIdentToken*)$5)->getName());
        nowFunc = nullptr;
        IdentToken::resetParamCount();
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
        parser.addIndent();
    }
    BlockItems RCURLY
    {
        auto faScope = nowScope->Parent();
        delete nowScope;
        nowScope = faScope;
        parser.removeIndent();
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
        auto cc = (IdentToken*)$1;
        if (cc->Type() != IntType)
            yyerror("Int identifier required.");

        auto lval = (IntIdentToken*)$1,
            rval = (IntIdentToken*)$3;

        if (lval->isConst())
            yyerror("Cannot assign values to a constant.");
        
        parser.addStmt(lval->getName() + " = " + rval->getName());
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
        parser.addStmt("return");
    }
    | RETURN Exp SEMI
    {
        if (nowFunc == nullptr)
            yyerror("Not in a function.");
        if (nowFunc->retType() != RetInt)
            yyerror("This function does not return int.");
        auto cid = (IntIdentToken*)$2;
        parser.addStmt("return " + cid->getName());
    }
    | IF LPAREN
    {
        auto newgroup = parser.newIf();
        $$ = newgroup;
    }
    Cond RPAREN
    {
        auto tags = (JumpLabelGroup*)$3;
        parser.addStmt(tags->trueTag + ":");
    }
    Stmt DanglingElse
    | WHILE LPAREN
    {
        auto whilestmt = parser.newWhile();
        parser.addStmt(whilestmt->beginTag + ":");
        $$ = whilestmt;
    }
    Cond RPAREN
    {
        auto tags = (JumpLabelGroup*)$3;
        parser.addStmt(tags->trueTag + ":");
    }
    Stmt
    {
        auto whilestmt = parser.lastWhile(true);
        parser.addStmt("goto " + whilestmt->beginTag, 1);
        parser.addStmt(whilestmt->falseTag + ":");
    }
    | CONT SEMI
    {
        auto whilestmt = parser.lastWhile();
        if (whilestmt == nullptr)
            yyerror("Not in a loop.");
        parser.addStmt("goto " + whilestmt->beginTag);
    }
    | BREAK SEMI
    {
        auto whilestmt = parser.lastWhile();
        if (whilestmt == nullptr)
            yyerror("Not in a loop.");
        parser.addStmt("goto " + whilestmt->falseTag);
    }
    ;

DanglingElse:   ELSE
    {
        auto thisif = parser.lastIf();
        parser.addStmt("goto " + thisif->endTag, 1);
        parser.addStmt(thisif->falseTag + ":");
    }
    Stmt
    {
        auto thisif = parser.lastIf(true); // pop this IfStmt
        parser.addStmt(thisif->endTag + ":");
    }
    | {
        auto thisif = parser.lastIf(true);
        parser.addStmt(thisif->falseTag + ":");
    }
    ;

Exp:    AddExp;
Cond: 
    {
        parser.newGroup();
    }
    LOrExp
    {
        auto lastgroup = parser.lastGroup(true);
        parser.addStmt(lastgroup->falseTag + ":");
        lastgroup = parser.lastGroup();
        parser.addStmt("goto " + lastgroup->falseTag);
    }
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
                newcid = new IntIdentToken(cid->getName(), to_string(offset*INTSIZE), downToEle);
            }
            else {
                auto idxVar = new IntIdentToken(); // The int token for the index
                parser.addDecl(idxVar, nowFunc);
                parser.addStmt(idxVar->getName() + " = " + to_string(offset*INTSIZE));
                string &idxName = idxVar->getName();

                int idxOffset, dims = indices.size();
                for (int i = 0; i < dims; ++i) {
                    if (indices[i]->isConst()) continue;

                    auto tmp = new IntIdentToken(); // The temp var for multiplication
                    parser.addDecl(tmp, nowFunc);
                    idxOffset = arrOp_access.ndim(i) * 4;
                    parser.addStmt(tmp->getName() + " = " + 
                            indices[i]->getName() + " * " + to_string(idxOffset));
                    parser.addStmt(idxName + " = " + idxName + " + " + tmp->getName());
                }
                newcid = new IntIdentToken(cid->getName(), idxVar->getName(), downToEle);
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
        auto cid = (IdentToken*)$1;
        if (cid->Type() == IntType) {
            auto intcid = (IntIdentToken*)cid;
            if (intcid->isSlice()) {
                auto newcid = new IntIdentToken();
                parser.addDecl(newcid, nowFunc);
                parser.addStmt(newcid->getName() + " = " + cid->getName());
                cid = newcid;
            }
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
            parser.addStmt("param " + param->getName());
        }

        if (func->retType() == RetInt) {
            auto cc = new IntIdentToken();
            parser.addDecl(cc, nowFunc);
            parser.addStmt(cc->getName() + " = call " + func->getName());
            $$ = cc;
        }
        else if (func->retType() == RetVoid) {
            parser.addStmt("call " + func->getName());
            $$ = new VoidToken();
        }
        else {
            yyerror("Unknown return type.");
        }
    }
    | IDENT LPAREN RPAREN
    {
        auto name = *(string*)$1;

        if (name == "starttime") {
            parser.addStmt("param " + to_string(yylineno));
            parser.addStmt("call f__sysy_starttime");
        }
        else if (name == "stoptime") {
            parser.addStmt("param " + to_string(yylineno));
            parser.addStmt("call f__sysy_stoptime");
        }
        else {
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
                parser.addDecl(cc, nowFunc);
                parser.addStmt(cc->getName() + " = call " + func->getName());
                $$ = cc;
            }
            else if (func->retType() == RetVoid) {
                parser.addStmt("call " + func->getName());
                $$ = new VoidToken();
            }
            else {
                yyerror("Unknown return type.");
            }
        }        
    }
    | ADD UnaryExp
    {
        auto cid = (IdentToken*)$2;
        if (cid->Type() != IntType)
            yyerror("Int identifier required.");
        $$ = cid;
    }
    | SUB UnaryExp
    {
        auto cc = (IdentToken*)$2;
        if (cc->Type() != IntType)
            yyerror("Int Identifier required.");

        auto cid = (IntIdentToken*)$2;
        if (cid->isConst())
            $$ = new IntIdentToken(-cid->Val());
        else {
            auto newcid = new IntIdentToken();
            parser.addDecl(newcid, nowFunc);
            parser.addStmt(newcid->getName() + " = -" + cid->getName());
            $$ = newcid;
        }
    }
    | NOT UnaryExp
    {
        auto cc = (IdentToken*)$2;
        if (cc->Type() != IntType)
            yyerror("Int Identifier required.");

        auto cid = (IntIdentToken*)$2;
        if (cid->isConst()) {
            $$ = new IntIdentToken((int)(!cid->Val()));
        }
        else {
            auto newcid = new IntIdentToken(); // A temporary var
            parser.addDecl(newcid, nowFunc);
            parser.addStmt(newcid->getName() + " = !" + cid->getName());
            $$ = newcid;
        }
    }
    ;
FuncParams: Exp
    ;
MulExp:     UnaryExp {$$ = $1;}
    | MulExp MUL UnaryExp
    {
        auto cc = (IdentToken*)$3;
        if (cc->Type() != IntType)
            yyerror("Int Identifier required.");
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            $$ = new IntIdentToken(c1->Val() * c2->Val());
        }
        else {
            auto newcid = new IntIdentToken(); // A tmp var
            parser.addDecl(newcid, nowFunc);
            parser.addStmt(newcid->getName() + " = " + c1->getName() + " * " + c2->getName());
            $$ = newcid;
        }
    }
    | MulExp DIV UnaryExp
    {
        auto cc = (IdentToken*)$3;
        if (cc->Type() != IntType)
            yyerror("Int Identifier required.");
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            if (c2->Val() == 0)
                yyerror("devided by zero!");
            $$ = new IntIdentToken(c1->Val() / c2->Val());
        }
        else {
            auto newcid = new IntIdentToken(); // A tmp var
            parser.addDecl(newcid, nowFunc);
            parser.addStmt(newcid->getName() + " = " + c1->getName() + " / " + c2->getName());
            $$ = newcid;
        }
    }
    | MulExp MOD UnaryExp
    {
        auto cc = (IdentToken*)$3;
        if (cc->Type() != IntType)
            yyerror("Int Identifier required.");
        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            if (c2->Val() == 0)
                yyerror("devided by zero!");
            $$ = new IntIdentToken(c1->Val() % c2->Val());
        }
        else {
            auto newcid = new IntIdentToken();
            parser.addDecl(newcid, nowFunc);
            parser.addStmt(newcid->getName() + " = " + c1->getName() + " % " + c2->getName());
            $$ = newcid;
        }
    }
    ;
AddExp:     MulExp {$$ = $1;}
    | AddExp ADD MulExp
    {
        auto cc = (IdentToken*)$3;
        if (cc->Type() != IntType)
            yyerror("Int Identifier required.");

        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            $$ = new IntIdentToken(c1->Val() + c2->Val());
        }
        else {
            auto newcid = new IntIdentToken();
            parser.addDecl(newcid, nowFunc);
            parser.addStmt(newcid->getName() + " = " + c1->getName() + " + " + c2->getName());
            $$ = newcid;
        }
    }
    | AddExp SUB MulExp
    {
        auto cc = (IdentToken*)$3;
        if (cc->Type() != IntType)
            yyerror("Int Identifier required.");

        auto c1 = (IntIdentToken*)$1, c2 = (IntIdentToken*)$3;
        if (*c1&&*c2) {
            $$ = new IntIdentToken(c1->Val() - c2->Val());
        }
        else {
            auto newcid = new IntIdentToken();
            parser.addDecl(newcid, nowFunc);
            parser.addStmt(newcid->getName() + " = " + c1->getName() + " - " + c2->getName());
            $$ = newcid;
        }
    }
    ;
RelExp:     AddExp
    {
        auto cc = (IdentToken*)$1;
        if (cc->Type() != IntType)
            yyerror("Int Identifier requireed.");

        auto exp = (IdentToken*)$1;
        auto cid = new BoolIdentToken(exp->getName(), false);
        $$ = cid;
    }
    | RelExp LE AddExp
    {
        auto c1 = (IdentToken*)$1, c2 = (IdentToken*)$3;
        auto cid = new BoolIdentToken(c1->getName() + " < " + c2->getName());
        parser.addDecl(cid, nowFunc);
        parser.addStmt(cid->getExp());
        $$ = cid;
    }
    | RelExp GE AddExp
    {
        auto c1 = (IdentToken*)$1, c2 = (IdentToken*)$3;
        auto cid = new BoolIdentToken(c1->getName() + " > " + c2->getName());
        parser.addDecl(cid, nowFunc);
        parser.addStmt(cid->getExp());
        $$ = cid;
    }
    | RelExp LEQ AddExp
    {
        auto c1 = (IdentToken*)$1, c2 = (IdentToken*)$3;
        auto cid = new BoolIdentToken(c1->getName() + " <= " + c2->getName());
        parser.addDecl(cid, nowFunc);
        parser.addStmt(cid->getExp());
        $$ = cid;
    }
    | RelExp GEQ AddExp
    {
        auto c1 = (IdentToken*)$1, c2 = (IdentToken*)$3;
        auto cid = new BoolIdentToken(c1->getName() + " >= " + c2->getName());
        parser.addDecl(cid, nowFunc);
        parser.addStmt(cid->getExp());
        $$ = cid;
    }
    ;
EqExp:      RelExp {$$ = $1;}
    | EqExp EQ RelExp
    {
        auto c1 = (IdentToken*)$1, c2 = (IdentToken*)$3;
        auto cid = new BoolIdentToken(c1->getName() + " == " + c2->getName());
        parser.addDecl(cid, nowFunc);
        parser.addStmt(cid->getExp());
        $$ = cid;
    }
    | EqExp NEQ RelExp
    {
        auto c1 = (IdentToken*)$1, c2 = (IdentToken*)$3;
        auto cid = new BoolIdentToken(c1->getName() + " != " + c2->getName());
        parser.addDecl(cid, nowFunc);
        parser.addStmt(cid->getExp());
        $$ = cid;
    }
    ;
LAndExp:    EqExp 
    {
        auto cid = (BoolIdentToken*)$1;
        auto lastgroup = parser.lastGroup();
        parser.addStmt("if " + cid->getName() + "==0 goto " + lastgroup->falseTag);
    }
    | LAndExp AND EqExp
    {
        auto cid = (BoolIdentToken*)$3;
        auto lastgroup = parser.lastGroup();
        parser.addStmt("if " + cid->getName() + "==0 goto " + lastgroup->falseTag);
    }
    ;
LOrExp:
    LAndExp
    {
        auto lastgroup = parser.lastGroup();
        parser.addStmt("goto " + lastgroup->trueTag);
    }
    |
    LOrExp
    {
        auto lastgroup = parser.lastGroup(true);
        parser.addStmt(lastgroup->falseTag + ":");
        parser.newGroup();
    }
    OR LAndExp
    {
        auto lastgroup = parser.lastGroup();
        parser.addStmt("goto " + lastgroup->trueTag);
    }
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
    cout << "Line " << yylineno << "," << charNum << ": " << s << endl;
    exit(1);
}

void yyerror(const string &s) {
    yyerror(s.c_str());
}

int main(int argc, char **argv) {
    ios::sync_with_stdio(false);
    if (argc >= 4)
        if ((yyin = fopen(argv[3], "r")) == NULL)
            yyerror("Cannot open input file.");
    
    if (argc >= 6)
        if (freopen(argv[5], "w", stdout) == NULL)
            yyerror("Cannot open output file.");

    nowScope->addToken(new FuncIdentToken(RetInt, "getint", 0));
    nowScope->addToken(new FuncIdentToken(RetInt, "getch", 0));
    nowScope->addToken(new FuncIdentToken(RetInt, "getarray", 1));
    nowScope->addToken(new FuncIdentToken(RetVoid, "putint", 1));
    nowScope->addToken(new FuncIdentToken(RetVoid, "putch", 1));
    nowScope->addToken(new FuncIdentToken(RetVoid, "putarray", 2));

    yyparse();
    parser.parse();

    fclose(yyin);
    return 0;
}