# Compiler-proj
编译大作业：SysY转Eeyore。

## 进度
- 2021/12/16-17: 实现解析器类`Parser`，改变程序翻译的方式，**改变较大**。实现布尔类型`CondIdentToken`，实现工具类`JumpLabelGroup`用于维护跳转列表。在Makefile中加入测试功能。**完成所有功能，通过了所有功能测试**。修改了几个Bug：
    - 修正了函数参数的Eeyore名。之前会全局使用`p0,p1,p2,p3`等编号，现在对于每个函数都会从0开始计数；
    - 实现短路原则。现在对于`if(a&&b)`，会分开翻译两个条件，当有一个不满足时就直接跳转到末尾；
    - 允许了数组作为函数参数；
    - 修复了数组切片的表示方式；如果有一个二维数组`a[2][5] (var 40 T0)`，那么`a[1]`会表示为`T0+20`而非`T0[20]`；
    - 修改了变量数组的初始化方式：
        1. 未赋予初值的数组不再初始化为0；
        2. 为数组声明添加专门的解析方式（在声明字符串前加一个符号@，由Parser解析并生成所有等于0的赋值语句），类里只储存被显式赋值的元素；
    - 修改了解析器输出声明的方式。原先会把所有变量的声明都输出在程序最前端，现在会**根据不同的作用域**分别输出到对应函数的最前端；
    - 在对常数取否时，显式把取否的值转为整型。即，`!cid->Val()` 改成 `(int)(!cid->Val())` 以匹配常数对应的构造函数。不然，`!cid->Val()` 会被视为一个布尔值，之后匹配整型类的另一个不知道哪个构造函数；
- 2021/12/14: 实现函数的调用，并实现一部分`Block`。
- 2021/12/13: 实现函数的声明。
- 2021/12/7: 实现变量数组的声明，以及常变量数组的访问。
- 2021/12/6: 实现整型变量、整型常量、数组常量的声明。
- 2021/12/5: 实现整型常量声明，并开发工具类集合`tokenclass`。
- 2021/11/30: 完成词法分析器。
- 2021/11/28: 配置Makefile并完成基本的词法分析器。
- 2021/10/24: 创建仓库。

## 学术诚信
我承诺严格遵守学术诚信。所有来自他人的代码段都会明确标出，其余所有代码都是个人工作。
- 多行注释的正则表达式来自Zhenbang You。我至今还不会推这个表达式；
- 将`yylval`定义成`void*`的想法来自Zhenbang You；
- 为作用域添加`is_param`成员的想法来自Zhenbang You；

## 镜像
这个仓库托管于课程GitLab上，并[镜像于GitHub](https://github.com/iamwyh2019/compiler-proj)上用来刷马赛克墙。如果代码跟本仓库有100%查重率请不要误杀。所有commit的提交用户名均为"yuhengwu"，邮箱均为"799810767@qq.com"。

## 工具类
`tokenclass.h`和`tokenclass.cpp`中定义了许多工具类用来表达编译中的实体和信息。与Zhenbang You不同，我希望通过类继承来明确区分不同类型的变量，并用私有变量和公有方法来减小程序的耦合程度。目前，它包含以下内容：
- `Token`：代表一切token的父类，成员变量`type`，包括`IntType`, `ArrayType`, `FuncType`, `VoidType`；
- `IdentToken`：代表所有标识符，包括常量和变量。成员变量有变量名、对应的Eeyore变量名，是否为常量，是否为临时变量，是否为函数变量等等；
- `VoidToken`：用来代表无返回值的函数（的返回值），作用是检查 `void f(){}; int a = f();` 类型的情况；
- `IntIdentToken`：代表整型类标识符，成员变量有变量值；
- `ArrayIdentToken`：代表数组类标识符，成员变量有维度信息。如果它是函数参数，则不储存值；如果它是常量，则会储存整个数组的值；如果它是变量，则会储存每个下标对应的表达式的指针。`ArrayOperator`负责处理访问与赋值；
- `FuncIdentToken`：代表函数类标识符，成员变量有参数信息。
- `Scope`：作用域，成员变量有一个`map<string, IdentToken*>`储存当前作用域的标识符，有一个指向上层作用域的指针。支持在当前作用域以及所有有效作用域内查找一个标识符，返回对应的类指针；
- `ArrayOperator`：数组操作器，通过`setTarget`登记要操作的数组。它是数组类的友类，可以访问后者的私有变量。它重载了[]来访问常量数组的内容，返回`int`；重载了()来访问变量数组的内容，返回`IntIdentToken*`。如果这一位没有明确确定，则为`nullptr`。
- `Parser`：解析器。它会记录所有的声明与语句，解析结束后统一**先**输出声明**再**输出语句。它还会跟踪每条语句的缩进情况。此外，它会维护跳转标签。这里有几个细节：
    - 语句的缩进情况由Block控制。具体来说，每进入一个Block，缩进就会加一级（多一个\t）；每离开一个Block就会减一级。例外是函数末尾的return语句会手动加上一级缩进，方法是为`addStmt`里面传入参数`ex_indent=1`。
    - 维护作用域当然也是解析器的职责，但是因为在实现解析器类的时候已经有很多直接跟`Scope`交互的代码了，解耦的工作量太大，因此就不把作用域嵌入解析器内了。
- `JumpLabelGroup`：维护跳转列表组，包括`beginTag, trueTag, falseTag, endTag`，分别代表代码段开头、条件成立的去处、条件不成立的去处、条件成立执行完后的去处（不成立的部分执行完会顺序往下）。

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

**灵感来自 Zhenbang You**：`yylval` 的类型默认为`int`，具体由 `YYSTYPE` 决定。为保证最大的灵活性，我们可以将它定义为 `void*` （通用指针），并用 `*yylval` （配上适当的指针类型转换）来访问具体值。具体来说，在scanner和parser里面都加上 `#deefine YYSTYPE void*` 就好。[一个参考链接](https://www.coder4.com/archives/3975).

在Bison中，我们用"$+数字"来访问匹配到的token的值。具体来说，如果有一个规则类似 `UNIT: EXP1 EXP2 EXP3`，那么右侧三个token的值分别为 $1 $2 $3。这个表达式的值（也就是`UNIT`的值）为 $$。注意在本项目中它们都是 `void*` 类型。

### 2021/12/6
今天处理了很多细节：
- 整型常量没有必要翻译成变量，只要前端内部记录它的值。但是数组常量需要翻译成变量，因为会有类似 `const_array[var_index]` 这样的访问。在 `IdentToken` 类中，有一个成员变量 `s_assign` (should_assign) 表示应不应该给它分配一个Eeyore变量。
- 如果所有计算都是常量计算（整型常量、数字、数组常量的元素之间的运算），可以在前端直接算完，此时要注意除0错误并报错。如果是变量计算，即使可以算出表达式的值（例如 `int a=5; int b=a;`）也不要算，直接翻译成对应的Eeyore代码。`IntIdentToken`的第二种构造函数针对计算过程中的常量（有数值，没有名字，不分配Eeyore变量），第三种构造函数针对计算过程中的变量（没有数值，没有名字，分配Eeyore变量）；
- `IntIdentToken` 的成员变量 `is_t` (is_tmp) 记录这个变量是不是运算过程中的临时变量。在变量赋值 `int a = ...` 中，如果右侧是常量或者非临时变量，就要为a创建一个新的变量；如果右侧是临时变量，只需要把a指向它就好，节省一步T1=T0的操作；

### 2021/12/7
今天实现了变量数组的声明，以及两种数组的访问。几个细节：
- 要为所有式子的等号左右两边（若有）分别声明一个`ArrayOperator`，因此要声明两个数组操作器。注意到形如`a[b[c[d]]]`的嵌套数组，只有内层处理成表达式后才会处理外一层的访问，因此不存在对`ArrayOperator`的竞争。
- 访问数组时，可以先统一把常量部分对应的offset算出来，一次性赋给下标临时变量，用来节省变量数。
- 只有当数组名和**所有**下标都是常量时，才认为它是一个常量，直接返回值，不创建新变量（`IntIdentToken`的第二种构造）；其它所有情况都生成新变量（第三种构造）。

### 2021/12/13
有时候，我们会在匹配到一半时就先执行一些操作。例如，匹配到函数声明时，在处理参数列表之前就生成新的局部作用域来记录函数的参数。即，在yacc里长这样：
```
SomeUnit:   EXP1 EXP2
    {
        // do something
    }
    EXP3 EXP4
    {
        // do something else
    }
    ;
```
此时要注意，执行完第一部分代码的结果会作为**一个新的值**，插在EXP2和EXP3之间。因此，之后想要引用EXP3的值时需要用$4而非$3，而$3引用的是第一部分的结果，也即第一部分的$$。[参考链接](https://perso.esiee.fr/~najmanl/compil/Bison/bison_6.html#SEC46)

### 2021/12/14
原有的工具类在处理函数参数时遇到了不小的问题：
- 原先的数组类在访问时会严格检查维数是否相同（确定到元素），但是由于函数调用时可以将高维数组的切片作为参数调用，因此这个检查只能放宽到维数是否不大于数组维数；
- 数组切片的类型很模糊。它是个指针，但类型上为`int`，共用`IntIdentToken`。这也导致编译时检查是否确定到元素变得困难；
- **灵感来自 Zhenbang You**：如何处理函数形参的作用域与函数体的作用域？由于`Block`自带作用域，函数形参形式上在这个代码块之外，但作用域属于它，因此需要在识别到函数声明后、识别参数列表前就生成局部作用域，并把这一作用域传给函数体的作用域，这必定会增加`Scope`类的复杂度。目前的解决方案是为`Scope`加一个属性`is_param`，标记它是不是函数形参作用域，在随后代码块作用域执行`findOne`时检查上一层作用域是否是形参域，若是则在里面也执行`findOne`。
- <del>由于Eeyore支持 `T1 = T0[4]` 这样的以数组元素为右值的语句，因此之前的机制中不会专门取出数组元素作为一个新变量。然而，`return`语句不支持直接返回数组元素。因此我们为`IntIdentToken`加了一个`is_slice`变量标记它是否是数组元素，若是，则在`return`语句中专门处理，其它情况不变。</del>&nbsp;&nbsp;反转了，Eeyore只有赋值语句能用数组元素作为右值。仍考虑记录`is_slice`，在`PrimaryExp`取`LVal`的时候将数组元素取出成单独的元素作为右值，而作为左值时不变。

### 2021/12/16
今天实现了`Parser`类，它会记录所有声明和语句，最后解析时**先**输出声明**再**输出语句。在这之前我们都是实时输出翻译结果，这在处理循环时不可避免地会重复声明变量，因此现在改用解析器统一输出解析结果。

因为现在翻译不是实时的了，所以我们为Makefile加入了test和selftest生成规则。`make selftest` 会用目录下的test文件夹（需要自己创建）里的test.sy作为输入结果，输出到同一文件夹下的test.ee。`make test`首先会执行selftest的步骤，然后用test.in作为eeyore的输入，调用MiniVM，输出到test.out中。

为了实现短路原则，在处理逻辑与 `a&&b` 时，不能统一算完两个表达式后再判断，应该按如下方式：
```
// compute a
if a==0 goto falseTag
// compute b
if b==0 goto falseTag
goto trueTag
```
此外，为了处理逻辑或，上述代码的`falseTag`不应该直接跳到表达式结尾，而应该跳到下一个逻辑与的表达式的开头；`trueTag`则直接跳到条件成立对应的语句。具体细节可见`Parser`中的`newGroup`对四个tag的处理。总之，对于形如 `if (a&&b || c&&d)` 的语句，应当如下翻译：
```
// compute a
if a==0 goto nextCondTag1
//compute b
if b==0 goto nextCondTag1
goto trueTag

nextCondTag1:
// compute c
if c==0 goto nextCondTag2
// compute d
if d==0 goto nextCondTag2
goto trueTag

nextCondTag2:
goto falseTag

trueTag:
// the main part of If
goto endTag

falseTag:
// the "else" part, or empty if there's no "else"

endTag:
// after the If
```


## 附录
几个链接：
- 嘉然今天吃什么：https://space.bilibili.com/672328094
- 向晚大魔王：https://space.bilibili.com/672346917
- 贝拉kira：https://space.bilibili.com/672353429
- 乃琳Queen：https://space.bilibili.com/672342685
- 珈乐Carol：https://space.bilibili.com/351609538