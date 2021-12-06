#include "tokenclass.h"

const int INTSIZE = 4;

const string emptyString = "";

// ============= Token =============
Token::Token(TokenType tp) {
    type = tp;
}
TokenType Token::Type() const {return type;}

// ============= IdentToken =============
int IdentToken::count = 0;
IdentToken::IdentToken(const string &_name, TokenType tp, bool is_const, bool is_tmp, bool is_param):
    Token(tp) {
        name = _name;
        is_c = is_const;
        is_p = is_param;
        is_t = is_tmp;

        if (!is_c) {
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
void IdentToken::setName(string &s) {name = s;}

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
    IdentToken(_name, IntType, is_const, is_tmp, is_param) {
        val = 0;
        if (is_c) eeyore_name = to_string(val);
    }
IntIdentToken::IntIdentToken(int v, bool is_const, bool is_tmp, bool is_param):
    IdentToken(emptyString, IntType, is_const, is_tmp, is_param) {
        val = v;
        if (is_c) eeyore_name = to_string(val);
    }

int IntIdentToken::Val() const {return val;}
void IntIdentToken::setVal(int v) {
    val = v;
    if (is_c) eeyore_name = to_string(val);
}
string IntIdentToken::Declare() const {
    return "var " + eeyore_name;
}

// ============= ArrayIdentToken =============
ArrayIdentToken::ArrayIdentToken(const string &_name, bool is_const, bool is_tmp, bool is_param):
    IdentToken(_name, ArrayType, is_const, is_tmp, is_param) {}

void ArrayIdentToken::setShape(vector<int> &_shape) {
    shape = _shape;
    dim = shape.size();
    for (int i = dim-2; i >= 0; --i)
        shape[i] *= shape[i+1];
    shape.push_back(1);
    // If it is a constant, store the values. Otherwise just store its shape
    if (is_c) vals = vector<int>(shape[0], 0);
}

const int ArrayIdentToken::size() const {
    return shape[0];
}

string ArrayIdentToken::Declare() const {
    return "var " + to_string(shape[0]*INTSIZE) + " " + eeyore_name;
}

// ============= Scope =============
Scope::Scope(const Scope *fa) {parent = fa;}

Scope::~Scope() {
    for (auto iter = scope.begin(); iter != scope.end(); ++iter)
        delete iter->second;
}

IdentToken* Scope::find(string &id, bool deep) const {
    auto now_scope = this;

    do {
        auto iter = this->scope.find(id);
        if (iter != this->scope.end())
            return iter->second;
        now_scope = now_scope->parent;
    } while (deep && now_scope != nullptr);
    
    return nullptr;
}

IdentToken* Scope::findOne(string &id) const {
    return find(id, false);
}

IdentToken* Scope::findAll(string &id) const {
    return find(id, true);
}

void Scope::addToken(IdentToken *tok) {
    scope[tok->Name()] = tok;
}


// ============= ArrayOperator =============
void ArrayOperator::setTarget(ArrayIdentToken *tgt) {
    target = tgt;
    layer = 0; index = 0;
}

bool ArrayOperator::addOne(int v) {
    if (index >= target->shape[0]) return false;
    target->vals[index++] = v;
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