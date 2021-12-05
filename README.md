# Compiler-proj
Project progress is updated here.

## Progress
- 2021/12/5: Defined token classes. Implemented constant declaration.
- 2021/11/30: Finished lexical analyzer and configured `yylval`.
- 2021/11/28: Started. Set up Makefile and finished basic scanner.
- 2021/10/24: Repo created.

## Academic Integrity
I hereby promise to strictly adhere to academic integrity. I will explicitly specify any line of code copied from others' works. All other codes are original work.

## Mirror
This repo is [mirrored in GitHub](https://github.com/iamwyh2019/compiler-proj). All commits are made under username "yuhengwu" and mirrored to the GitHub repo with username "iamwyh2019".

## Notes
### 2021/11/28
This project runs like this:
1. `parser.y` implements a CFG. It will find all defined tokens and convert them into an enum type specified in `parser.tab.h`.
2. `scanner.l` imports this header file, implements a scanner that identifies tokens, and exports the code to `{BUILD_DIR}/scanner.cpp`.
3. Compile `scanner.cpp` and `parser.tab.c` to get a frontend.

Flex compiles regular expressions in sequential order, so remember to put reserved words **before** identifiers.

### 2021/11/30
There are some builtin variables:
- `yytext`: the token currently matched
- `yyleng`: the length of `yytext`
- `yylval`: the *value* of the token. Most tokens have no value, except that:
    - Integer constant has token value equal to its value (tricky)
    - Identifier has token value equal to its name
    - We can also add support for real number constants and string constants.

**One point inspired by Zhenbang You**: the type of `yylval` is specified by `YYSTYPE` and is `int` on default. We can define it as `void*` (universal pointer) to support various types, and use `*yylval` to access its value (as long as you know its type). To do this, write `#define YYSTYPE void*` in both scanner and parser. You may also refer [here](https://www.coder4.com/archives/3975).

Say in the parser there's a rule like: UNIT:  EXP1 EXP2 EXP3. We can access the value of EXP1, EXP2, EXP3 with $1 $2 $3 respectively.

### 2021/12/5
Zhenbang's code defines a large flat class `Var` to represent all identifiers (const, number, variable, array, etc.), which is good but not very elegant. I will try using different classes.