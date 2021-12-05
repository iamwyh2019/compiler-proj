#ifndef TOKEN_CLASS
#define TOKEN_CLASS

#include <iostream>
#include <string>
#include <map>
using std::string;
using std::map;

enum TokenType {
    IntType,
    ArrayType
};

// The general token class
// Type: token type
class Token {
    TokenType type;
    string name;
public:
    Token(string&, TokenType);
    TokenType Type() const;
    string& Name();
};

// Identifier
// Name: name of the identifier
// TokenType: either int or array
// is_const: whether it is a constant
class IdentToken: public Token {
    bool is_c;
public:
    IdentToken(string&, bool, TokenType);
    bool isConst() const;
};

// IntIdentToken, has TokenType int
// Name: name of the identifier
// is_const: whether it is a constant
class IntIdentToken: public IdentToken {
    int val;
public:
    IntIdentToken(string&, bool);
    int Val() const;
    void setVal(int);
};

// Scope
// parent: the scope one level above it; the global scope is nullptr
// find: the internal find function. encapsulated as findOne and findAll for easier use.
// findOne: given a name, find the token in THIS scope; return the Token pointer
// findAll: given a name, find the token in ALL scopes; return the Token pointer
// addToken: add a token to this scope. WILL NOT add to parent scope
class Scope {
    map<string, Token*> scope;
    const Scope *parent;
    Token* find(string&, bool) const;
public:
    Scope(const Scope *fa=nullptr);
    ~Scope();
    Token* findOne(string&) const;
    Token* findAll(string&) const;
    void addToken(Token*);
};

#endif