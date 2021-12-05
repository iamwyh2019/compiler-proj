#include "tokenclass.h"

Token::Token(){}

IdentToken::IdentToken(string &_name):
    name(_name) {val=0;}

string& IdentToken::Name() {return name;}
int IdentToken::Val() {return val;}
void IdentToken::setVal(int v) {val = v;}