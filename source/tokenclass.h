#ifndef TOKEN_CLASS
#define TOKEN_CLASS

#include <iostream>
#include <string>
using std::string;

class Token {
public:
    Token();
};

class IdentToken: public Token {
    int val;
    string name;
public:
    IdentToken(string&);
    string& Name();
    int Val();
    void setVal(int);
};

#endif