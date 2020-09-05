算法模型很重要，但落地的工程能力同样不可缺少。考虑到计算速度和运行效率，一些线上系统会选择使用`C++`语言。最近正好遇到这样的一个项目（推荐系统的排序模块），于是归零心态，从头开始。从Makefile文件开始，构建C++项目。


## 1. Makefile、make、CMake的关系

> 首先回答为什么会有这些文件的出现：

假设我们编写了一个C++程序，如何让它运行起来，大体的过程是这样的：编写程序源代码 -> 编译器编译成目标代码 -> 链接程序生成可执行代码。
比如我编写了一个hello_world.cpp，我可以通过如下命令来进行编译和链接（生成的hello_world即是可执行文件）：
```bash
g++ hello_world.cpp -o hello_world
```
当我们只有一个或几个源文件时，可以用`g++`(GNU编译器套件，主要用来编译C++)命令进行编译；但一个大型的C++工程，可能设计到多个文件并相互依赖，这个时候如果再单个去编译，效率极低且工作量大，容易出错，所以出现了make工具。

### 1.1 make
make是linux下的一个命令，它本身没有编译和链接的功能，但它可以依赖一个通常称为Makefile的文件进行构建。

还拿刚刚的hello_world编译的例子。我们可以在hello_world.cpp这个工程的同级目录下新建一个Makefile文件，内容为：
```shell
hello_world：
    g++ hello_world.cpp -o hello_world -- 可以是任何的shell命令，如cp a.txt b.txt
```
然后执行`make hello_world`命令，则会同样生成可执行文件`hello_world`。

**Tips**：
1. make只是一个根据指定的Shell命令进行构建的工具。它的构建依赖于Makefile文件定义的规则。
2. make不仅仅可以构建C/C++工程，还可以构建Java、Node.JS等其他工程。

### 1.2 Makefile

Makefile是指示make程序如何工作的命令文件。对工程而言，Makefile编写的好坏会影响开发效率（尤其是大型工程体现更明显）。


Makefile文件中最重要的规则，一条规则（rule）讲述了：目标（target）需要依赖什么前置条件（prerequisites）且需要执行什么命令来构建这个目标。

对于Makefile文件如何编写，以及常用的语法，将会在后面详细的说明。

### 1.3 CMake和CMakeLists.txt

CMake是一个跨平台的自动化构建系统，它是比make更高级的编译配置工具，它的优点体现在：

1. Makefile文件中的编译相关命令依赖于平台，如果平台更换了该文件可能需要大量修改，而CMake可以根据不同平台、不同编译器，生成相应的Makefile。
2. CMake是依赖于CMakeLists.txt文件来生成Makefile的。CMakeLists.txt需要手工编写，也可以通过编写脚本进行半自动的生成。


## 2. Makefile Demo示例
该部分给一个测试的Makefile文件demo以及执行make命令的结果。然后分析每一条命令的含义。

### 2.1 Makefile示例
```shell
CC:= g++
CFLAGS := -c -Wall -std=c++14 -g
ROOT:= ..
INCLUDES:= -I$(ROOT)
LDFLAGS:= -lm -lglog -lcppunit
SOURCES:= main_test.cpp ServiceTest.cpp
OBJECTS:= $(SOURCES:.cpp=.o)
LIBDIR:= -L$(ROOT)
EXECUTABLE= main_test
.PHONY: all clean
all: $(EXECUTABLE)
    @echo "-- start unit tests --"
    @chmod +x main_test;./main_test
$(EXECUTABLE): $(OBJECTS)
	$(CC) $(OBJECTS) $(LIBDIR) $(LDFLAGS) -o $@
.cpp.o:
	$(CC) $(CFLAGS) $(INCLUDES) $< -o $@
clean:
	rm -rf  $(OBJECTS) $(EXECUTABLE)
```
### 2.2 make执行结果
```shell
=> make
g++ -c -Wall -std=c++14 -g -I.. main_test.cpp -o main_test.o
g++ -c -Wall -std=c++14 -g -I.. ServiceTest.cpp -o ServiceTest.o
g++ main_test.o erviceTest.o -L.. -lm -lglog -lcppunit -o main_test
-- start unit tests --
I1130 08:39:00.256619   337 ServiceTest.cpp:10] ServiceTest::setUp
I1130 08:39:00.256974   337 ServiceTest.cpp:29] ServiceTest value: you just said: echo test!
I1130 08:39:00.257009   337 ServiceTest.cpp:16] ServiceTest::tearDown



OK (1 tests)
```

### 2.3 Makefile文件命令各个击破
下面将一条条分析这个demo中的语法命令，并和第二部分介绍的知识点相对应。

| 命令  | 说明 | 对应知识点 |
| :------ | :------ | :------ |
| CC:= g++ | 变量CC指定编译器为`g++` | 变量和赋值符 |
| CFLAGS := -c -Wall -std=c++14 -g | 变量CFLAG指定`g++`的编译命令：<br> -c：只编译不链接生成可执行文件，<br> -Wall：编译后显示所有错误或警告，<br> -std=c++14：指定`c++`标准，<br> -g：可以用gdb调试 | 变量和赋值符<br> 编译命令选项 |
| ROOT:= .. | 变量ROOT存储项目根目录 | 变量和赋值符 |
| INCLUDES:= -I$(ROOT) | -Idir：告诉编译器优先在指定的dir目录查找头文件 | 变量和赋值符<br> 编译命令选项 |
| LDFLAGS:= -lm -lglog -lcppunit | -llibrary：指定编译时使用的库，本demo使用到了glog和cppunit两个库 | 变量和赋值符<br> 编译命令选项 |
|SOURCES:= main_test.cpp ServiceTest.cpp <br>OBJECTS:= $(SOURCES:.cpp=.o)|# .cpp=.o的意思是指将SOURCES下所有以.cpp结尾的文件的.cpp替换为.o|变量和赋值符<br>替换后缀名|
| LIBDIR:= -L$(ROOT) | -Ldir：指定编译的时候搜索库的路径 | 变量和赋值符<br>编译命令选项 |
| EXECUTABLE= main_test | 注意赋值运算符：=、:= | 赋值运算符 |
| .PHONY: all clean | .PHONY是一个伪目标，防止定义的执行命令的目标和实际文件出现名字冲突| 内置目标名 |
| all: $(EXECUTABLE) <br> &nbsp; &nbsp; &nbsp; &nbsp; @echo "-- start unit tests --" <br> &nbsp; &nbsp; &nbsp; &nbsp; @chmod +x main_test;./main_test | 定义了Makefile的第一条规则，并运行main_test | 变量调用<br>规则<br>关闭回声 |
|$(EXECUTABLE): $(OBJECTS) <br> &nbsp; &nbsp; &nbsp; &nbsp; $(CC) $(OBJECTS) $(LIBDIR) $(LDFLAGS) -o $@ | 定义了Makefile的第二条规则，$@指代当前目标 | 规则<br>自动变量 |
| .cpp.o: <br> &nbsp; &nbsp; &nbsp; &nbsp; $(CC) $(CFLAGS) $(INCLUDES) $< -o $@ | 老式的后缀规则，告诉编译器如何将源文件识别为输出文件。 | 后缀规则 <br> 自动变量|
|clean: <br> &nbsp; &nbsp; &nbsp; &nbsp; rm -rf  $(OBJECTS) $(EXECUTABLE)|定义clean规则|规则|

## 3. Makefile文件语法

### 3.1 规则
make命令依据Makefile文件中的规则进行构建，所以第一步就是要明确规则怎么定义和编写。

**规则形式定义**

如下，每条规则就是用来明确：构建目标的前置条件是什么，如何构建目标。
```
<target> : <prerequisites> -- 目标：前置条件
[Tab键] <commands>          -- Tab键后面跟要执行的shell命令
```
其中："目标"是必需的，不可省略；"前置条件"和"命令"是可选的，但是至少存在一个。

假设规则编写完毕后，在当前目录下执行`make target`即可按照规则执行命令，**若直接执行`make`不指定target，则make会去执行makefile文件的第一个规则**。

#### 3.1.1 目标
目标有两种：文件名，某个操作的名字。分别讲述这两种情况：

**目标是文件名**：
注意：文件名可以是一个，也可以是多个（多个文件名间用空格隔开），示例：
```shell
result.txt: source.txt
    cp source.txt result.txt
```

如果当前目录下存在source.txt，执行`make result.txt`命令，则会在当前目录下cp source.txt文件生成result.txt。


**目标是某个操作的名字**：
目标是某个操作的名字，这种目标称为“伪目标”。该名字可以是用户自定义，也可以是内置目标名（如：.PHONY）。示例：
```
cp:
    # 拷贝测试
    cp source.txt cp.txt
```
如果当前目录下存在source.txt，执行`make cp`命令，截图如下：

<img src="../Pics/makefile_demo.png" width="600">

**值得一提的.PHONY伪目标**：

前面我们定义了一个伪目标cp，但如果当前目录正好有个同名的文件叫“cp”，则`make cp`命令将不生效，因为检测到cp已经存在了，没有必要再重新生成。解决办法是用`.PHONY`来声明伪目标，如下：
```
.PHONY cp
```
.PHONY是内置目标，在cp规则前这样声明后，make在执行规则前就不会去检查是否有cp这个文件存在，而是去直接执行对应的命令了。

#### 3.1.2 前置条件
前置条件是目标的依赖项，通常是一组文件（空格隔开）。前置条件的另一个作用是用来判断目标什么时候需要被重新构建：
1. 当前置条件不存在（需要先生成前置条件）
2. 当前置条件有更新（如何判断有更新：前置文件的last-modification时间戳比目标的时间戳新）

#### 3.1.3 命令
命令表示目标应该如何被构建。命令前需要有一个Tab键（默认的）。

每一行的命令在一个单独的shell中执行，这些shell间没有依赖关系。所以，如果要执行的多条命令间有依赖关系，用如下方式解决：

1. 将有依赖关系的命令写在一行（分号隔开），示例：

    ```shell
    all: $(EXECUTABLE)
        @chmod +x main_test;./main_test # 先对main_test赋执行权限，然后再执行该文件
    ```
    
2. 命令写在多行，在前一行的命令末尾加上反斜杠（类似python的换行），示例：
    ```shell
    all: $(EXECUTABLE)
        @chmod +x main_test; \
        @./main_test 
    ```

3. 命令写在多行，但在整体规则前加上`.ONESHELL:`命令。示例：
    ```shell
    .ONESHELL:
    all: $(EXECUTABLE)
        @chmod +x main_test; 
        @./main_test 
    ```

### 3.2 变量和赋值符

#### 变量
Makefile文件中允许使用变量，变量在被调用时需要放在`$()`中。变量有如下几种类型：

##### 1. 自定义变量：即用户自己定义的变量
##### 2. 自动变量：自动变量的值与当前的规则有关，常用的有如下几个：
- **$@**：指代当前目标

    ```shell
    => cat Makefile
    test_1:
        # 测试$@
        @echo $@
    ```
    运行结果：
    ```bash
    => make test_1
    # 测试test_1
    test_1
    ```
    
- **$<**：指代第一个前置条件
    
    ```shell
    => cat Makefile
    test_2: source.txt
        # 测试$<
        @echo $<
    ```
    运行结果：
    ```shell
    => make test_2
    # 测试source.txt
    source.txt
    ```
    
- **$^**：指代所有前置条件

- **$?**：指代比目标时间戳更新的所有前置条件。

    
**Tips**：更多的`自动变量`可以参考链接：[Automatic-Variables](https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html)


#### 赋值运算符
我们可能注意到在前面的Demo示例中，出现了不同的赋值符号（如：`:=`、`=`），不同的符号其实代表了不同的含义，总结如下：
1. **:=** &nbsp; &nbsp; 该运算符是在定义时赋值(静态扩展)。示例：
    ```shell
    str_1 = aaa
    str_2 := $(str_1) test

    str_1 = bbb
    str_2:
        @echo $(str_2)
    ```

    执行`make str_2`命令，结果如下：
    
    <img src="../Pics/makefile_result_1.png" width="230">

2. **=** &nbsp; &nbsp; 该运算符是在执行时赋值(动态扩展)，即如果新赋值，会保存最新的结果。示例：
    ```shell
    str_1 = aaa
    str_3 = $(str_1) test

    str_1 = bbb
    str_3:
        @echo $(str_3)
    ```

    执行`make str_3`命令，结果如下：

    <img src="../Pics/makefile_result_2.png" width="150">

    
3. **?=** &nbsp; &nbsp; 只有在该变量为空时才设置值。

4. **+=** &nbsp; &nbsp; 将值追加到变量尾端。

### 3.3 替换后缀名
.cpp=.o
在上面的demo中，用到了`替换后缀名`这个功能，写法是：**变量 + 冒号 + 原来的后缀名 + 等号 + 替换后的后缀名**
```
OBJECTS:= $(SOURCES:.cpp=.o)
```
**Tips**：替换后缀名功能是`patsubst函数`的一种简写形式。

### 3.4 回声
正常情况下，make会打印每一条命令并执行，叫做`回声`(echoing)。通过在命令前面添加**@**符号可以关闭回声。

在第二部分的demo中，all规则如下：
```shell
all: $(EXECUTABLE)
    @echo "-- start unit tests --"
    @chmod +x main_test;./main_test
```

如果我们将前面的 **@** 符号去掉，即去掉回声，则运行结果如下：

```shell
=> make
g++ -c -Wall -std=c++14 -g -I.. main_test.cpp -o main_test.o
g++ -c -Wall -std=c++14 -g -I.. ServiceTest.cpp -o ServiceTest.o
g++ main_test.o erviceTest.o -L.. -lm -lglog -lcppunit -o main_test
echo "-- start unit tests --"
-- start unit tests --
chmod +x main_test;./main_test
I1130 08:39:00.256619   337 ServiceTest.cpp:10] ServiceTest::setUp
I1130 08:39:00.256974   337 ServiceTest.cpp:29] ServiceTest value: you just said: echo test!
I1130 08:39:00.257009   337 ServiceTest.cpp:16] ServiceTest::tearDown



OK (1 tests)
```

### 3.5 后缀规则
demo中的`.cpp.o`是一个老式的后缀规则，告诉编译器如何将源文件识别为输出文件。

编译器将会自动将.cpp识别为源文件（`$<`）后缀，而.o识别为输出文件（`$@`）后缀。特别需要注意的是，后缀规则不允许任何依赖文件，但也不能没有命令。
```shell
.cpp.o:
	$(CC) $(CFLAGS) $(INCLUDES) $< -o $@
```
## 4. g++编译常用命令

| 命令  | 说明 | 
| :------ | :------ | 
|-c|编译为目标代码（机器代码），生成.o的文件|
|-Wall|打印出编译器所有的错误或警告|
|-w|关闭所有警告|
|-std|如 -std=c++14 指定c++标准|
|-g|允许产生能被 GNU 调试器使用的调试信息|
|-o|编译选项来为将产生的可执行文件指定文件名|
|-l|指定程序要链接的库|
|-L|指定库文件的搜索目录|
|-I|指定头文件目录|


## 总结
如上算是对makefile的一个入门理解，更多的经验需要从真正的参与编写一个完整的工程中收获。

## 附参考链接：
1. https://www.ibm.com/developerworks/cn/linux/l-cn-cmake/index.html
2. http://www.ruanyifeng.com/blog/2015/02/make.html