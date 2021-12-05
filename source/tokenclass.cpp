#include "tokenclass.h"

Token::Token(TokenType tp):
    type(tp) {}

TokenType Token::Type() const {return type;}

IdentToken::IdentToken(string &_name):
    Token(IntType), name(_name) {val=0;}

string& IdentToken::Name() {return name;}
int IdentToken::Val() {return val;}
void IdentToken::setVal(int v) {val = v;}