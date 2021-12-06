#include "tokenclass.h"

const int INTSIZE = 4;

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
int IdentToken::count = 0;
IdentToken::IdentToken(string &_name, TokenType tp, bool is_const, bool is_param):
    Token(tp) {
        name = _name;
        is_c = is_const;
        is_p = is_param;
        num = count++;
        num_text = to_string(num);
    }
IdentToken::~IdentToken(){}
string& IdentToken::Name() {return name;}
bool IdentToken::isConst() const {return is_c;}
string IdentToken::getName() const{
    if (is_p) return "p" + num_text;
    else return "T" + num_text;
}

// ============= IntIdentToken =============
IntIdentToken::IntIdentToken(string &_name, bool is_const):
    IdentToken(_name, IntType, is_const) {val = 0;}

int IntIdentToken::Val() const {return val;}
void IntIdentToken::setVal(int v) {val = v;}
string IntIdentToken::Decl() const {
    return "var " + getName();
}

// ============= ArrayIdentToken =============
ArrayIdentToken::ArrayIdentToken(string &_name, bool is_const):
    IdentToken(_name, ArrayType, is_const) {
        dim = 0;
        shape = vector<int>(1,0);
    }

void ArrayIdentToken::setShape(vector<int> &_shape) {
    shape = _shape;
    dim = shape.size();
    for (int i = dim-2; i >= 0; --i)
        shape[i] *= shape[i+1];
    shape.push_back(1);
}

const int ArrayIdentToken::size() const {
    return shape[0];
}

string ArrayIdentToken::Decl() const {
    return "var " + to_string(shape[0]*INTSIZE) + " " + getName();
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