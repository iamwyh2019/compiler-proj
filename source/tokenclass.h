#ifndef TOKEN_CLASS
#define TOKEN_CLASS

#include <iostream>
#include <string>
using std::string;

enum TokenType {
    IntType,
    ArrayType
};

class Token {
    TokenType type;
public:
    Token(TokenType);
    TokenType Type() const;
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