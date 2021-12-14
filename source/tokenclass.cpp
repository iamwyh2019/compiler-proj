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
int IdentToken::count = 0;
IdentToken::IdentToken(const string &_name, TokenType tp, bool should_assign,
                        bool is_const, bool is_tmp, bool is_param):
    Token(tp) {
        name = _name;
        is_c = is_const;
        is_p = is_param;
        is_t = is_tmp;
        s_assign = should_assign;

        if (s_assign) {
            num = count++;
            if (is_param)
                eeyore_name = "p" + to_string(num);
            else
                eeyore_name = "T" + to_string(num);
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

IntIdentToken::IntIdentToken(string &arrName, string index):
    IdentToken(emptyString, IntType, false, false, false, false) {
        is_slice = true;
        eeyore_name = arrName + '[' + index + ']';
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
    shape.push_back(1);
    // If it is a parameter, don't use it
    if (is_p) return;
    // If it is a constant, store the values. Otherwise store the reference to its values
    if (is_c) vals = deque<int>(shape[0], 0);
    else tokens = deque<IntIdentToken*>(shape[0], nullptr);
}

const int ArrayIdentToken::size() const {
    return shape[0];
}

string ArrayIdentToken::Declare() const {
    return "var " + to_string(shape[0]*INTSIZE) + " " + eeyore_name;
}

// ============= FuncToken =============
FuncIdentToken::FuncIdentToken(RetType return_type, string &_name):
    IdentToken(_name, FuncType, false, false, false, false) {
        ret_type = return_type;
        eeyore_name = "f_" + _name;
        n_params = 0;
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
    target->tokens[index++] = v;
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

IntIdentToken* ArrayOperator::operator()(int i) {
    return target->tokens[i];
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