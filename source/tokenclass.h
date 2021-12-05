#ifndef TOKEN_CLASS
#define TOKEN_CLASS

#include <iostream>
#include <string>
using std::string;

class Token {
    int lineno, charno;
public:
    Token(int, int);
    int lineNo() const;
    int charNo() const;
};

class NumberToken: public Token {
    int val;
public:
    NumberToken(int, int, int);
    int Val() const;
};

class IdentToken: public Token {
    int val;
    string name;
public:
    IdentToken(int, int, char*);
    string& Name();
};

#endif