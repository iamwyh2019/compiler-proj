#include "tokenclass.h"

Token::Token(int ln, int cn):
    lineno(ln), charno(cn) {}

int Token::lineNo() const {return lineno;}
int Token::charNo() const {return charno;}

NumberToken::NumberToken(int ln, int cn, int v):
    Token(ln,cn), val(v) {}

int NumberToken::Val() const {return val;}

IdentToken::IdentToken(int ln, int cn, char *_name):
    Token(ln, cn), name(_name) {}

string& IdentToken::Name() {return name;}