#ifndef TOKEN_CLASS
#define TOKEN_CLASS

#include <iostream>
#include <string>
#include <map>
#include <vector>
using std::string;
using std::to_string;
using std::map;
using std::vector;

enum TokenType {
    IntType,
    ArrayType,
};



// The general token class
// Type: token type
class Token {
    TokenType type;
public:
    Token(TokenType);
    TokenType Type() const;
};

// IntToken, just an int literal
// is_const: whether it is derived from a const
// NUMBER and constants are const
// Calculation between them are all const
// Otherwise it is variable
class IntToken: public Token {
    int val;
    bool is_c;
public:
    IntToken(int, bool);
    int Val() const;
    bool isConst() const;
    bool operator&(const IntToken&) const;
};

// Identifier
// Name: name of the identifier
// TokenType: either int or array
// is_const: whether it is a constant
// is_param: is this a parameter or a global variable
class IdentToken: public Token {
    bool is_c, is_p;
    string name, num_text;
    static int count;
    int num;
public:
    IdentToken(string&, TokenType, bool=false, bool=false);
    bool isConst() const;
    string& Name();
    string getName();
};

// IntIdentToken, has TokenType int
// val: the value of the token
class IntIdentToken: public IdentToken {
    int val;
public:
    IntIdentToken(string&, bool);
    int Val() const;
    void setVal(int);
};

// ArrayIdentToken, has TokenType array
// shape: the dimension of the array
// vals: flatten the array into an one-dim array
// dim: dimension
class ArrayIdentToken: public IdentToken {
    vector<int> shape;
    int dim;
public:
    ArrayIdentToken(string&, bool);
    void setShape(vector<int>&);
    const int size() const;
};

// Scope
// parent: the scope one level above it; the global scope is nullptr
// find: the internal find function. encapsulated as findOne and findAll for easier use.
// findOne: given a name, find the token in THIS scope; return the Token pointer
// findAll: given a name, find the token in ALL scopes; return the Token pointer
// addToken: add a token to this scope. WILL NOT add to parent scope
class Scope {
    map<string, IdentToken*> scope;
    const Scope *parent;
    IdentToken* find(string&, bool) const;
public:
    Scope(const Scope *fa=nullptr);
    ~Scope();
    IdentToken* findOne(string&) const;
    IdentToken* findAll(string&) const;
    void addToken(IdentToken*);
};

#endif