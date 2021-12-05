#include "tokenclass.h"

Token::Token(string &_name, TokenType tp) {
    name = _name;
    type = tp;
}

TokenType Token::Type() const {return type;}
string& Token::Name() {return name;}

IdentToken::IdentToken(string &_name, bool is_const, TokenType tp):
    Token(_name, tp), is_c(is_const) {}

IntIdentToken::IntIdentToken(string &_name, bool is_const):
    IdentToken(_name, is_const, IntType), val(0) {}

int IntIdentToken::Val() const {return val;}

void IntIdentToken::setVal(int v) {val = v;}

Scope::Scope(const Scope *fa) {parent = fa;}

Scope::~Scope() {
    for (auto iter = scope.begin(); iter != scope.end(); ++iter)
        delete iter->second;
}

Token* Scope::find(string &id, bool deep) const {
    auto now_scope = this;

    do {
        auto iter = this->scope.find(id);
        if (iter != this->scope.end())
            return iter->second;
        now_scope = now_scope->parent;
    } while (deep && now_scope != nullptr);
    
    return nullptr;
}

Token* Scope::findOne(string &id) const {
    return find(id, false);
}

Token* Scope::findAll(string &id) const {
    return find(id, true);
}

void Scope::addToken(Token *tok) {
    scope[tok->Name()] = tok;
}