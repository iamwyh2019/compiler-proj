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
IdentToken::IdentToken(const string &_name, TokenType tp, bool is_const, bool is_param, bool is_tmp):
    Token(tp) {
        name = _name;
        is_c = is_const;
        is_p = is_param;

        if (!(is_const && is_tmp)) {
            num = count++;
            if (is_param)
                eeyore_name = "p" + to_string(num);
            else
                eeyore_name = "T" + to_string(num);
        }
        else {
            eeyore_name = name;
        }
    }
IdentToken::~IdentToken(){}
string& IdentToken::Name() {return name;}
bool IdentToken::isConst() const {return is_c;}
string IdentToken::getName() const{
    return eeyore_name;
}
bool IdentToken::operator&(const IdentToken &b) const {
    return is_c && b.is_c;
}

// ============= IntIdentToken =============
IntIdentToken::IntIdentToken(const string &_name, bool is_const, bool is_param, bool is_tmp):
    IdentToken(_name, IntType, is_const, is_param, is_tmp) {val = 0;}
IntIdentToken::IntIdentToken(int v, bool is_const, bool is_tmp):
    IdentToken(to_string(v), IntType, is_const, false, is_tmp) {val = v;}

int IntIdentToken::Val() const {return val;}
void IntIdentToken::setVal(int v) {val = v;}
string IntIdentToken::Declare() const {
    return "var " + getName();
}

// ============= ArrayIdentToken =============
ArrayIdentToken::ArrayIdentToken(const string &_name, bool is_const, bool is_param, bool is_tmp):
    IdentToken(_name, ArrayType, is_const, is_param, is_tmp) {}

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

string ArrayIdentToken::Declare() const {
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