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

// Identifier
// Name: name of the identifier
// TokenType: either int or array
// is_const: whether it is a constant
// is_param: is this a parameter or a global variable
class IdentToken: public Token {
protected:
    bool is_c, is_p, is_t;
    string name, eeyore_name;
    static int count;
    int num;
public:
    IdentToken(const string&, TokenType, bool=false, bool=false, bool=false);
    virtual ~IdentToken()=0;

    bool isConst() const;
    bool isTmp() const;
    bool isParam() const;
    void setConst(bool);
    void setTmp(bool);
    void setParam(bool); 
    
    string& Name(); // Get the variable name
    void setName(string&); // set the variable name
    string& getName(); // Get the eeyore name

    virtual string Declare() const=0;

    bool operator&&(const IdentToken&b) const;
    bool operator||(const IdentToken&b) const;
};

// IntIdentToken, has TokenType int
// val: the value of the token
class IntIdentToken: public IdentToken {
    int val;
public:
    IntIdentToken(const string&, bool, bool=false, bool=false);
    IntIdentToken(int, bool=true, bool=false, bool=false);
    int Val() const;
    void setVal(int);
    virtual string Declare() const;
};

// ArrayIdentToken, has TokenType array
// shape: the dimension of the array
// vals: flatten the array into an one-dim array
// dim: dimension
class ArrayIdentToken: public IdentToken {
    vector<int> shape;
    vector<int> vals;
    int dim;
public:
    ArrayIdentToken(const string&, bool, bool=false, bool=false);
    void setShape(vector<int>&);
    const int size() const;
    virtual string Declare() const;
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


// ArrayOperator, used to manipulate arrays
class ArrayOperator {
    ArrayIdentToken *target;
    int layer;
public:
    void setTarget(ArrayIdentToken*);
};

#endif