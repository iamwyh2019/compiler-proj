#include "tokenclass.h"

const string emptyString = "";

extern const int INTSIZE;

// ============= Token =============
Token::Token(TokenType tp) {
    type = tp;
}
TokenType Token::Type() const {return type;}

// ============= VoidToken =============
VoidToken::VoidToken():
    IdentToken(emptyString, VoidType, false, false, false, false) {}

string VoidToken::Declare() const {
    return emptyString;
}

// ============= IdentToken =============
int IdentToken::global_count = 0;
int IdentToken::param_count = 0;
IdentToken::IdentToken(const string &_name, TokenType tp, bool should_assign,
                        bool is_const, bool is_tmp, bool is_param):
    Token(tp) {
        name = _name;
        is_c = is_const;
        is_p = is_param;
        is_t = is_tmp;
        s_assign = should_assign;

        if (s_assign) {
            if (is_param)
                eeyore_name = "p" + to_string(param_count++);
            else
                eeyore_name = "T" + to_string(global_count++);
        }
    }
IdentToken::~IdentToken(){}
string& IdentToken::Name() {return name;}
string& IdentToken::getName() {return eeyore_name;}
void IdentToken::setVarName(string &s) {name = s;}
void IdentToken::setName(string &s) {eeyore_name = s;}

bool IdentToken::isConst() const {return is_c;}
bool IdentToken::isTmp() const {return is_t;}
bool IdentToken::isParam() const {return is_p;}
void IdentToken::setConst(bool is_const) {is_c = is_const;}
void IdentToken::setTmp(bool is_tmp) {is_t = is_tmp;}
void IdentToken::setParam(bool is_param) {is_p = is_param;}

bool IdentToken::operator&&(const IdentToken &b) const {
    return is_c && b.is_c;
}
bool IdentToken::operator||(const IdentToken &b) const {
    return is_t | b.is_t;
}

void IdentToken::resetParamCount() {
    param_count = 0;
}

// ============= IntIdentToken =============
IntIdentToken::IntIdentToken(const string &_name, bool is_const, bool is_tmp, bool is_param):
    IdentToken(_name, IntType, !is_const, is_const, is_tmp, is_param) {
        // If it is a const, don't assign
        val = 0;
        is_slice = false;
        if (is_c) eeyore_name = to_string(val);
    }
IntIdentToken::IntIdentToken(int v, bool is_tmp, bool is_param):
    IdentToken(emptyString, IntType, false, true, is_tmp, is_param) {
        // This is a const. Don't assign.
        val = v;
        is_slice = false;
        if (is_c) eeyore_name = to_string(val);
    }
IntIdentToken::IntIdentToken(bool is_tmp, bool is_param):
    IdentToken(emptyString, IntType, true, false, is_tmp, is_param) {is_slice = false;}

IntIdentToken::IntIdentToken(string &arrName, const string &index, bool downToEle):
    IdentToken(emptyString, IntType, false, false, false, false) {
        is_slice = true;
        if (downToEle)
            eeyore_name = arrName + '[' + index + ']';
        else
            eeyore_name = arrName + " + " + index;
    }

int IntIdentToken::Val() const {return val;}
void IntIdentToken::setVal(int v) {
    val = v;
    if (is_c) eeyore_name = to_string(val);
}
string IntIdentToken::Declare() const {
    return "var " + eeyore_name;
}
bool IntIdentToken::isSlice() const {
    return is_slice;
}

// ============= ArrayIdentToken =============
ArrayIdentToken::ArrayIdentToken(const string &_name, bool is_const, bool is_tmp, bool is_param):
    IdentToken(_name, ArrayType, true, is_const, is_tmp, is_param) {
        // Always assign
    }

void ArrayIdentToken::setShape(deque<int> &_shape) {
    shape = _shape;
    dim = shape.size();
    for (int i = dim-2; i >= 0; --i)
        shape[i] *= shape[i+1];
    shape.emplace_back(1);
    // If it is a parameter, don't use it
    if (is_p) return;
    // If it is a constant, store the values. Otherwise store the reference to its values
    if (is_c) vals = deque<int>(shape[0], 0);
}

const int ArrayIdentToken::size() const {
    return shape[0];
}

string ArrayIdentToken::Declare() const {
    return "var " + to_string(shape[0]*INTSIZE) + " " + eeyore_name;
}

// ============= FuncToken =============
FuncIdentToken::FuncIdentToken(RetType return_type, const string &_name, int nparams):
    IdentToken(_name, FuncType, false, false, false, false) {
        ret_type = return_type;
        eeyore_name = "f_" + _name;
        n_params = nparams;
    }

void FuncIdentToken::setNParams(int nparams) {
    n_params = nparams;
}

string FuncIdentToken::Declare() const {
    return eeyore_name + " [" + to_string(n_params) + "]";
}

RetType FuncIdentToken::retType() const {
    return ret_type;
}

int FuncIdentToken::nParams() const {
    return n_params;
}

// ============= CondIdentToken =============
BoolIdentToken::BoolIdentToken(const string &exp, bool should_assign):
    IdentToken(exp, BoolType, should_assign, false, false, false) {
        if (!should_assign)
            eeyore_name = exp;
    }

string BoolIdentToken::Declare() const {
    return "var " + eeyore_name;
}

const string BoolIdentToken::getExp(){
    return eeyore_name + " = " + name;
}

// ============= Scope =============
Scope::Scope(Scope *fa, bool is_param) {
    parent = fa;
    is_p = is_param;
}

Scope::~Scope() {
    for (auto iter = scope.begin(); iter != scope.end(); ++iter) {
        delete iter->second;
    }
}

IdentToken* Scope::findOne(string &id) const {
    auto iter = scope.find(id);
    if (iter != scope.end())
        return iter->second;
    if (parent != nullptr && parent->is_p) {
        iter = parent->scope.find(id);
        if (iter != parent->scope.end())
            return iter->second;
    }
    return nullptr;
}

IdentToken* Scope::findAll(string &id) const {
    auto now_scope = this;

    while (now_scope != nullptr) {
        auto iter = now_scope->scope.find(id);
        if (iter != now_scope->scope.end())
            return iter->second;
        now_scope = now_scope->parent;
    }
    
    return nullptr;
}

void Scope::addToken(IdentToken *tok) {
    scope[tok->Name()] = tok;
}

Scope* Scope::Parent() const {
    return parent;
}


// ============= ArrayOperator =============
void ArrayOperator::setTarget(ArrayIdentToken *tgt) {
    target = tgt;
    layer = 0; index = 0;
    _name = tgt->getName();
}

bool ArrayOperator::addOne(int v) {
    if (index >= target->shape[0]) return false;
    target->vals[index++] = v;
    return true;
}

bool ArrayOperator::addOne(IntIdentToken *v) {
    if (index >= target->shape[0]) return false;
    target->tokens.emplace_back(make_pair(index++, v));
    return true;
}

bool ArrayOperator::moveDown() {
    ++layer;
    if (layer > target->dim) return false;
    index = ((index+target->shape[layer]-1) / target->shape[layer]) * target->shape[layer];
    return true;
}

bool ArrayOperator::moveUp() {
    --layer;
    index = ((index+target->shape[layer]-1) / target->shape[layer]) * target->shape[layer];
    return true;
}

bool ArrayOperator::jumpOne() {
    if (layer >= target->dim) return false;
    index += target->shape[layer];
    return true;
}

string& ArrayOperator::name() {
    return _name;
}

long unsigned int ArrayOperator::size() const {
    return target->size();
}

long unsigned int ArrayOperator::dim() const {
    return target->dim;
}

int ArrayOperator::ndim(int i) const {
    return target->shape[i+1];
}

int ArrayOperator::operator[](int i) {
    return target->vals[i];
}

pair<int, IntIdentToken*>& ArrayOperator::operator()(int i) {
    return target->tokens[i];
}

int ArrayOperator::nTokens() const {
    return target->tokens.size();
}



int ArrayOperator::getOffset(deque<IntIdentToken*> &indices) {
    int offset = 0, nowidx, avaidx, nidx = indices.size();
    for (int i = 0; i < nidx; ++i) {
        if (!indices[i]->isConst())
            continue;
        nowidx = indices[i]->Val();
        avaidx = target->shape[i] / target->shape[i+1];
        if (avaidx >= 0 && nowidx >= avaidx)
            return -1;
        offset += nowidx * target->shape[i+1];
    }
    return offset;
}

// ============= Parser =============
Parser::Parser() {
    label = 0;
    indent = 0;
}

void Parser::addDecl(const string &decl, FuncIdentToken *nowFunc) {
    if (nowFunc == nullptr)
        decls.emplace_back(decl);
    else
        addDeclInFunc(nowFunc->getName(), decl);
}

void Parser::addDecl(IdentToken *cid, FuncIdentToken *nowFunc) {
    // Declarations are never indented
    addDecl(cid->Declare(), nowFunc);
}

// ex_indent: extra indentation
// used for special indented statements, such as return
void Parser::addStmt(const string &stmt, int ex_indent) {
    stmts.emplace_back(stmt);
    indents.emplace_back(indent + ex_indent);
}

void Parser::addStmt(IdentToken *cid, int ex_indent) {
    addStmt(cid->Declare(), ex_indent);
}

void Parser::addDeclInFunc(const string& funcName, const string& decl) {
    funcDecls[funcName].emplace_back(decl);
}

void Parser::addDeclInFunc(const string& funcName, IdentToken *token) {
    addDeclInFunc(funcName, token->Declare());
}

string Parser::nextTag() {
    int num = label++;
    return "l" + to_string(num);
}

JumpLabelGroup::JumpLabelGroup(JumpType tp) {
    type = tp;
}

JumpLabelGroup* Parser::_newGroup(JumpType tp) {
    auto newif = new JumpLabelGroup(tp);
    newif->trueTag = nextTag();
    newif->falseTag = nextTag();
    newif->beginTag = nextTag();
    newif->endTag = nextTag();
    return newif;
}

JumpLabelGroup* Parser::newIf() {
    auto newif = _newGroup(IfType);
    ifstmts.emplace(newif);
    allstmts.emplace(newif);
    return newif;
}

JumpLabelGroup* Parser::lastIf(bool pop) {
    if (ifstmts.empty())
        return nullptr;
    auto lastif = ifstmts.top();
    if (pop) {
        ifstmts.pop();
        allstmts.pop();
    }
    return lastif;
}

JumpLabelGroup* Parser::newWhile() {
    auto newwhile = _newGroup(WhileType);
    whilestmts.emplace(newwhile);
    allstmts.emplace(newwhile);
    return newwhile;
}

JumpLabelGroup* Parser::lastWhile(bool pop) {
    if (whilestmts.empty())
        return nullptr;
    auto lastwhile = whilestmts.top();
    if (pop) {
        whilestmts.pop();
        allstmts.pop();
    }
    return lastwhile;
}

JumpLabelGroup* Parser::newGroup() {
    auto newgroup = new JumpLabelGroup(PhonyType);
    newgroup->trueTag = allstmts.top()->trueTag;
    newgroup->falseTag = nextTag();
    allstmts.emplace(newgroup);
    whilestmts.emplace(newgroup);
    ifstmts.emplace(newgroup);
    return newgroup;
}

JumpLabelGroup* Parser::lastGroup(bool pop) {
    if (allstmts.empty())
        return nullptr;
    auto lastgroup = allstmts.top();
    if (pop) {
        allstmts.pop();
        whilestmts.pop();
        ifstmts.pop();
    }
    return lastgroup;
}

void Parser::addIndent() {
    ++indent;
}

void Parser::removeIndent() {
    --indent;
}

void Parser::printDecls(vector<string> &decs, int indent) {
    string dec, sub, arrName;
    int tot, pos;
    for (auto &decl: decs) {
        for (int i = 0; i < indent; ++i)
            cout << "\t";
        if (decl[0] == '@') {
            cout << decl.substr(1) << endl;
            //"@var 24 T0"
            // Decode into arr length and name
            dec = decl.substr(5);
            pos = dec.find(' ');
            sub = dec.substr(0, pos);
            arrName = dec.substr(pos+1);

            tot = stoi(sub, 0, 10);
            for (int i = 0; i < tot; i += 4)
                cout << arrName << "[" << i << "] = 0" << endl;
        }
        else
            cout << decl << endl;
    }
}

void Parser::parse() {
    printDecls(decls, 0);

    int nstmts = stmts.size();
    string fname;

    for (int i = 0; i < nstmts; ++i) {
        auto &stmt = stmts[i];
        for (int j = 0; j < indents[i]; ++j)
            cout << "\t";
        cout << stmt << endl;

        if (stmt[0] == 'f' && stmt[1] == '_'){ // Function definition
            fname = stmt.substr(0, stmt.find(' '));
            auto &func_decls = funcDecls[fname];
            printDecls(func_decls, indents[i]+1);
        }
    }
}