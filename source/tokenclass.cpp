#include "tokenclass.h"

// ============= Token =============
Token::Token(TokenType tp) {
    type = tp;
}
TokenType Token::Type() const {return type;}

// ============= IntToken =============
IntToken::IntToken(int v, bool is_const):
    Token(IntType) {val = v; is_c = is_const;}
int IntToken::Val() const {return val;}
bool IntToken::isConst() const {return is_c;}
bool IntToken::operator&(const IntToken &b) const {return is_c && b.is_c;}

// ============= IdentToken =============
IdentToken::IdentToken(string &_name, bool is_const, TokenType tp):
    Token(tp) {name = _name; is_c = is_const;}
string& IdentToken::Name() {return name;}
bool IdentToken::isConst() const {return is_c;}

// ============= IntIdentToken =============
IntIdentToken::IntIdentToken(string &_name, bool is_const):
    IdentToken(_name, is_const, IntType) {val = 0;}

int IntIdentToken::Val() const {return val;}
void IntIdentToken::setVal(int v) {val = v;}

// ============= ArrayIdentToken =============
ArrayIdentToken::ArrayIdentToken(string &_name, bool is_const):
    IdentToken(_name, is_const, ArrayType) {
        dim = 0;
        shape = vector<int>(1,0);
    }

void ArrayIdentToken::setShape(vector<int> &_shape) {
    shape = _shape;
    dim = shape.size();
    for (int i = dim-2; i >= 0; --i)
        shape[i] *= shape[i+1];
    vals = vector<int>(shape[0], 0); // All initialized as zero
    shape.push_back(1);
}

const int ArrayIdentToken::size() const {
    return shape[0];
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