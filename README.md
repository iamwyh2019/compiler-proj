# Compiler-proj
编译大作业：SysY转Eeyore。

## 进度
- 2021/12/6: 实现整型变量、整型常量、数组常量的声明。
- 2021/12/5: 实现整型常量声明，并开发工具类集合`tokenclass`。
- 2021/11/30: 完成词法分析器。
- 2021/11/28: 配置Makefile并完成基本的词法分析器。
- 2021/10/24: 创建仓库。

## 学术诚信
我承诺严格遵守学术诚信。所有来自他人的代码段都会明确标出，其余所有代码都是个人工作。
- 多行注释的正则表达式来自Zhenbang You。我至今还不会推这个表达式；
- 将`yylval`定义成`void*`的想法来自Zhenbang You；

## 镜像
这个仓库托管于课程GitLab上，并[镜像于GitHub](https://github.com/iamwyh2019/compiler-proj)上用来刷马赛克墙。如果代码跟本仓库有100%查重率还请不要误杀。所有commit的提交用户名均为"yuhengwu"，邮箱均为"799810767@qq.com"。

## 工具类
`tokenclass.h`和`tokenclass.cpp`中定义了许多工具类用来表达编译中的实体和信息。目前，它包含以下内容：
- `Token`：代表一切token的父类，成员变量`type`，目前可选`IntType`和`ArrayType`，之后会加上`FuncType`等；
- `IdentToken`：代表所有标识符，包括常量和变量。成员变量有变量名、对应的Eeyore变量名，是否为常量，是否为临时变量，是否为函数变量等等；
- `IntIdentToken`：代表整型类标识符，成员变量有变量值；
- `ArrayIdentToken`：代表数组类标识符，成员变量有维度信息。如果它是常量，则会储存整个数组的值；如果它是变量，只会储存维度信息，由`ArrayOperator`翻译访问语句；
- `Scope`：作用域，成员变量有一个`map<string, IdentToken*>`储存当前作用域的标识符，有一个指向上层作用域的指针。支持在当前作用域以及所有有效作用域内查找一个标识符，返回对应的类指针；
- `ArrayOperator`：处理数组操作。目前支持常量数组初始化；

## 笔记
### 2021/11/28
项目运行流程大致如下
1. `parser.y` 实现了一个CFG。它会将所有在本文件中定义的token转为一个枚举类型，存于 `parser.tab.h` 中。
2. `scanner.l` 读入此头文件，实现一个词法分析器，利用正则表达式识别token，并把所有代码导出到 `{BUILD_DIR}/scanner.cpp`。
3. `tokenclass.h` 和 `tokenclass.cpp` 实现了一些工具类，例如整型变量、数组变量、作用域、数组操作等。编译这两个文件得到 `{BUILD_DIR}/tokenclass.o`。
4. 编译 `scanner.cpp`、`parser.tab.c`、`tokenclass.o` 得到前端。

Flex会按文件内书写的顺序从上到下匹配token，所以要把保留字放在标识符前面。

### 2021/11/30
词法分析器里有几个内置的变量：
- `yytext`: 目前匹配到的字符串；
- `yyleng`: `yytext` 的长度；
- `yylval`: 这个token的值（若有）。注意这个值和token类型（比如NUMBER, LCURLY这样的类型）不一样。大部分token都没有值，除了：
    - 常数的值等于它的值；
    - 标识符的值等于它的名字（变量名）；

**灵感来自 Zhenbang You**: `yylval` 的类型默认为`int`，具体由 `YYSTYPE` 决定。为保证最大的灵活性，我们可以将它定义为 `void*` （通用指针），并用 `*yylval` （配上适当的指针类型转换）来访问具体值。具体来说，在scanner和parser里面都加上 `#deefine YYSTYPE void*` 就好。[一个参考链接](https://www.coder4.com/archives/3975).

在Bison中，我们用"$+数字"来访问匹配到的token的值。具体来说，如果有一个规则类似 `UNIT: EXP1 EXP2 EXP3`，那么右侧三个token的值分别为 $1 $2 $3。这个表达式的值（也就是`UNIT`的值）为 $$。注意在本项目中它们都是 `void*` 类型。

### 2021/12/6
今天处理了很多细节：
- 整型常量没有必要翻译成变量，只要前端内部记录它的值。但是数组常量需要翻译成变量，因为会有类似 `const_array[var_index]` 这样的访问。在 `IdentToken` 类中，有一个成员变量 `s_assign` (should_assign) 表示应不应该给它分配一个Eeyore变量。
- 如果所有计算都是常量计算（整型常量、数字、数组常量的元素之间的运算），可以在前端直接算完，此时要注意除0错误并报错。如果是变量计算，即使可以算出表达式的值（例如 `int a=5; int b=a;`）也不要算，直接翻译成对应的Eeyore代码。`IntIdentToken`的第二种构造函数针对计算过程中的常量（有数值，没有名字，不分配Eeyore变量），第三种构造函数针对计算过程中的变量（没有数值，没有名字，分配Eeyore变量）；
- `IntIdentToken` 的成员变量 `is_t` (is_tmp) 记录这个变量是不是运算过程中的临时变量。在变量赋值 `int a = ...` 中，如果右侧是常量或者非临时变量，就要为a创建一个新的变量；如果右侧是临时变量，只需要把a指向它就好，节省一步T1=T0的操作；