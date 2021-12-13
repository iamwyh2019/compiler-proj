#ifndef TOKEN_CLASS
#define TOKEN_CLASS

#include <iostream>
#include <string>
#include <map>
#include <deque>
#include <queue>
using std::string;
using std::to_string;
using std::map;
using std::deque;
using std::deque;

const int INTSIZE = 4;

enum TokenType {
    IntType,
    ArrayType,
    FuncType,
};

enum RetType {
    RetVoid,
    RetInt,
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
    bool is_c, is_p, is_t, s_assign;
    string name, eeyore_name;
    static int count;
    int num;
public:
    IdentToken(const string&, TokenType, bool, bool=false, bool=false, bool=false);
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
    IntIdentToken(int, bool=false, bool=false); // Constant int in the middle
    IntIdentToken(bool=true, bool=false); // temporary variable in the middle. Don't care about its value.
    int Val() const;
    void setVal(int);
    virtual string Declare() const;
};

// ArrayIdentToken, has TokenType array
// shape: the dimension of the array
// vals: flatten the array into an one-dim array
// dim: dimension
class ArrayIdentToken: public IdentToken {
    deque<int> shape;
    deque<int> vals;
    deque<IntIdentToken*> tokens;
    int dim;
    friend class ArrayOperator;
public:
    ArrayIdentToken(const string&, bool, bool=false, bool=false);
    void setShape(deque<int>&);
    const int size() const;
    virtual string Declare() const;
};

// FuncToken
// Represent functions
class FuncIdentToken: public IdentToken {
    RetType ret_type;
    int n_params;
public:
    FuncIdentToken(RetType, string&);
    void setNParams(int);
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
    int layer, index;
    string _name;
public:
    void setTarget(ArrayIdentToken*);
    bool addOne(int); // For constant array, add one element to values;
    bool addOne(IntIdentToken*); // For var array, add one token to tokens
    bool moveDown(); // Meet {
    bool moveUp(); // Meet }
    bool jumpOne(); // Meet {}
    int getOffset(deque<IntIdentToken*>&);
    long unsigned int size() const;
    long unsigned int dim() const;
    int ndim(int i) const;
    string& name();

    int operator[](int); // To access value (for constant array)
    IntIdentToken* operator()(int); // To access member (for var array)
};

#endif