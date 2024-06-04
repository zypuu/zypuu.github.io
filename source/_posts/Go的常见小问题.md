---
title: GO的常见小问题
date: 2021-03-18 16:02:20
tags: go
categories: GO
comments: true
description: go语言的常见问题记录
---

### byte与int

### byte与字符串

### strings转换

### for循环字符串

### 简短模式

``` javascript
var size := 1024
```

这种是不对的，会报错


### 常量内存分配 

``` javascript
package main
const cl  = 100

var bl    = 123

func main()  {
    println(&bl,bl)
    println(&cl,cl)
}
```
会报错
常量不同于变量的在运行期分配内存，常量通常会被编译器在预处理阶段直接展开，作为指令数据使用

### goto

``` javascript
func main()  {

    for i:=0;i<10 ;i++  {
    loop:
        println(i)
    }
    goto loop
}
```

goto不能跳转到其他函数或者内层代码

### 新类型强转

``` javascript
func main()  {
     type MyInt1 int
    type MyInt2 = int
    var i int =9
    var i1 MyInt1 = i
    var i2 MyInt2 = i
}


type User struct {
}
type MyUser1 User
type MyUser2 = User
func (i MyUser1) m1(){
    fmt.Println("MyUser1.m1")
}
func (i User) m2(){
    fmt.Println("User.m2")
}

func main() {
    var i1 MyUser1
    var i2 MyUser2
    i1.m1()
    i2.m2()
}
```

会报错，myint的是新类型，得强转，不能直接赋值

第二个，user取了别名myuser1，myuser1没有m2方法，执行失败


### nil切片和空切片指向地址

指向数组的引用地址不一样

nil切片是0，不存在
空切片是指向一个固定的地址，所有的空切片都指向这个地址

var slice []int 创建出来的 slice 其实是一个 nil slice。它的长度和容量都为0。和nil比较的结果为true。这里比较混淆的是empty slice，empty slice的长度和容量也都为0，但是所有的空切片的数据指针都指向同一个地址 0xc42003bda0。空切片和 nil 比较的结果为false

### 字符串转换数组，内存拷贝问题

会发生内存拷贝，只要发生类型强转，都会发生内存拷贝

go的unsafe包
``` javascript
unsafe.Pointer(&a)方法可以得到变量a的地址
(*reflect.StringHeader)(unsafe.Pointer(&a)) 可以把字符串a转成底层结构的形式
(*[]byte)(unsafe.Pointer(&ssh))可以把ssh底层结构体转成byte的切片的指针。
再通过 *转为指针指向的实际内容
```

### 反转含有中文，数字，字符串的字符

``` javascript
package main

import"fmt"

func main() {
 src := "你好abc啊哈哈"
 dst := reverse([]rune(src))
 fmt.Printf("%v\n", string(dst))
}

func reverse(s []rune) []rune {
 for i, j := 0, len(s)-1; i < j; i, j = i+1, j-1 {
  s[i], s[j] = s[j], s[i]
 }
 return s
}
```

rune关键字，从golang源码中看出，它是int32的别名（-2^31 ~ 2^31-1），比起byte（-128～127），可表示更多的字符。
由于rune可表示的范围更大，所以能处理一切字符，当然也包括中文字符。在平时计算中文字符，可用rune。
因此将字符串转为rune的切片，再进行翻转，完美解决


### 拷贝大切片，小切片的代价

并不是，所有切片的大小相同；三个字段（一个uintptr，两个int）。切片中的第一个字是指向切片底层数组的指针，这是切片的存储空间，第二个字段是切片的长度，第三个字段是容量。将一个 slice 变量分配给另一个变量只会复制三个机器字。所以 拷贝大切片跟小切片的代价应该是一样的

大切片跟小切片的区别无非就是 Len 和 Cap的值比小切片的这两个值大一些，如果发生拷贝，本质上就是拷贝上面的三个字段


### uintptr和unsafe.Pointer的区别

unsafe.Pointer只是单纯的通用指针类型，用于转换不同类型指针，它不可以参与指针运算；
而uintptr是用于指针运算的，GC 不把 uintptr 当指针，也就是说 uintptr 无法持有对象， uintptr 类型的目标会被回收；
unsafe.Pointer 可以和 普通指针 进行相互转换；
unsafe.Pointer 可以和 uintptr 进行相互转换

``` javascript
package main

import (
 "fmt"
 "unsafe"
)

type W struct {
 b int32
 c int64
}

func main() {
 var w *W = new(W)
 //这时w的变量打印出来都是默认值0，0
 fmt.Println(w.b,w.c)

 //现在我们通过指针运算给b变量赋值为10
 b := unsafe.Pointer(uintptr(unsafe.Pointer(w)) + unsafe.Offsetof(w.b))
 *((*int)(b)) = 10
 //此时结果就变成了10，0
 fmt.Println(w.b,w.c)
}
```

uintptr(unsafe.Pointer(w)) 获取了 w 的指针起始值
unsafe.Offsetof(w.b) 获取 b 变量的偏移量
两个相加就得到了 b 的地址值，将通用指针 Pointer 转换成具体指针 ((*int)(b))，通过 * 符号取值，然后赋值。*((*int)(b)) 相当于把 (*int)(b) 转换成 int 了，最后对变量重新赋值成 10，这样指针运算就完成了

### map不初始化会怎么样

map不初始化，可以取值，取出来的值是空

不能赋值，赋值会panic异常

空map和nil map结果是一样的，都是map[]， 判断是否为空， map==nil

delete一个nil map也不会panic

### map初始化和不初始化的区别

初始化map是有长度的，可以赋值，操作，默认值。不初始化无法赋值

### map的遍历删除

map的range遍历删除是安全的，可以一边遍历一边删除，但是删除完后，占用的内存一直不释放，map = nil释放内存

### go的字符串修改

字符串是不能修改的，天生线程安全，大家使用的都是只读对象，无须加锁；再者，方便内存共享，而不必使用写时复制（Copy On Write）等技术；字符串 hash 值也只需要制作一份

怎么修改，转为byte数组进行替换，最后通过string强转

``` javascript
angleBytes := []byte(angel)
for i := 5; i <= 10; i++ {
    angleBytes[i] = ' '
}

```

### 判断一个数组是否已经排序

sort包的，isSorted方法

sort包

``` javascript
type Interface interface {
        // 获取数据集合元素个数
        Len() int
        // 如果 i 索引的数据小于 j 索引的数据，返回 true，且不会调用下面的 Swap()，即数据升序排序。
        Less(i, j int) bool
        // 交换 i 和 j 索引的两个元素的位置
        Swap(i, j int)
}

```

### slice和map的并发安全处理

slice在并发执行中不会报错，但是数据会丢失

方法：1，索引处理，全局索引，2：加锁， 3：channel处理

map并发会报错

方法：1，加锁，2：sync.map

### 数组与切片的区别

1、切片是指针类型， 数组是值类型

2、数组的长度是固定的，切片不是，切片是动态数组

3、切片比数组多一个属性，cap容量

4、切片的底层是数组

### json包使用，结构体里tag问题

如果变量首字母小写，则为private。无论如何不能转，因为取不到反射信息

如果变量首字母大写，则为public。

不加tag，可以正常转为json里的字段，json内字段名跟结构体内字段原名一致。
加了tag，从struct转json的时候，json的字段名就是tag里的字段名，原字段名已经没用。


### slice的深拷贝和 浅拷贝

浅拷贝对于值类型的话是完全拷贝一份，而对于引用类型是拷贝其地址。也就是拷贝的对象修改引用类型的变量同样会影响到源对象

P2 := P1就是浅拷贝，如何避免，重新给定地址，重新生成一个

深拷贝 deepCopy(dst, src interface{})

对于深拷贝就比较好了解了，任何对象都会被完完整整的拷贝一份，拷贝对象与被拷贝对象不存在如何联系，也就不会互相影响。如果你需要拷贝的对象中没有引用类型，那么对于Golang而言使用浅拷贝就可以


### for range循环，for里append

``` javascript
 s := []int{1,2,3,4,5}
 for _, v:=range s {
  s =append(s, v)
  fmt.Printf("len(s)=%v\n",len(s))
 }
```

不会死循环，for range其实是golang的语法糖，在循环开始前会获取切片的长度 len(切片)，然后再执行len(切片)次数的循环。


### 读写已经关闭的channel会怎样

读已经关闭的 chan 能一直读到东西，但是读到的内容根据通道内关闭前是否有元素而不同。
如果 chan 关闭前，buffer 内有元素还未读 , 会正确读到 chan 内的值，且返回的第二个 bool 值（是否读成功）为 true。
如果 chan 关闭前，buffer 内有元素已经被读完，chan 内无值，接下来所有接收的值都会非阻塞直接成功，返回 channel 元素的零值，但是第二个 bool 值一直为 false。
因为如果接收值的地址 ep 不为空
那接收值将获得是一个该类型的零值
typedmemclr 会根据类型清理相应地址的内存
这就解释了上面代码为什么关闭的 chan 会返回对应类型的零值


写已经关闭的 chan 会 panic，
因为源码当 c.closed != 0 则为通道关闭，此时执行写，源码提示直接 panic，输出的内容就是上面提到的 "send on closed channel"

### 对未初始化的channel进行读写会怎样

读写未初始化的 chan 都会阻塞

未初始化的 chan 此时是等于 nil，当它不能阻塞的情况下，直接返回 false，表示读写 chan 失败

当 chan 能阻塞的情况下，则直接阻塞 gopark方法，读写抛出错误


### for循环select

如果通道已经关闭会怎么样？如果select中的case只有一个，又会怎么样？

``` javascript
c := make(chan int)
go func () {
	c <- 10
	close(c)
}

for {
	select{
	case x, ok := <-c:
		if !ok {
			c = nil
		}
	default:

	}
}
```


for循环select时，如果其中一个case通道已经关闭，则每次都会执行到这个case。

怎样不读关闭的channel，根据channel读关闭的会返回false，根据false判断
x, ok := <-c 返回的值里第一个x是通道内的值，ok是指通道是否关闭，当通道被关闭后，ok则返回false，因此可以根据这个进行操作x, ok := <-c 返回的值里第一个x是通道内的值，ok是指通道是否关闭，当通道被关闭后，ok则返回false，因此可以根据这个进行操作

执行c = nil 将通道置为nil，相当于读一个未初始化的通道，则会一直阻塞， seleect会跳过这个阻塞

如果select里边只有一个case，而这个case被关闭了，则会出现死循环。

如果像上面置为nil去解决，则会引发别的问题

第一次读取case能读到通道里的10
第二次读取case能读到通道已经关闭的信息。此时将通道置为nil
第三次读取case时main协程会被阻塞，此时整个进程没有其他活动的协程了，进程deadlock


### goalng内存逃逸

golang程序变量会携带有一组校验数据，用来证明它的整个生命周期是否在运行时完全可知。如果变量通过了这些校验，它就可以在栈上分配。否则就说它 逃逸 了，必须在堆上分配

在一个切片上存储指针或带指针的值。 一个典型的例子就是 []* string

在方法内把局部变量指针返回 局部变量原本应该在栈中分配，在栈中回收。但是由于返回时被外部引用，因此其生命周期大于栈，则溢出

slice 的背后数组被重新分配了，因为 append 时可能会超出其容量( cap )。 slice 初始化的地方在编译时是可以知道的，它最开始会在栈上分配。如果切片背后的存储要基于运行时的数据进行扩充，就会在堆上分配 


### 怎样避免内存逃逸

在runtime/stubs.go:133有个函数叫noescape。noescape可以在逃逸分析中隐藏一个指针。让这个指针在逃逸分析中不会被检测为逃逸

noescape() 函数的作用是遮蔽输入和输出的依赖关系。使编译器不认为 p 会通过 x 逃逸， 因为 uintptr() 产生的引用是编译器无法理解的。


### 内存泄漏相关问题

``` javascript
package main

import (
 "fmt"
 "io/ioutil"
 "net/http"
 "runtime"
)

func main() {
 num := 6
 for index := 0; index < num; index++ {
  resp, _ := http.Get("https://www.baidu.com")
  _, _ = ioutil.ReadAll(resp.Body)
 }
 fmt.Printf("此时goroutine个数= %d\n", runtime.NumGoroutine())
}
```

上面这道题在不执行resp.Body.Close()的情况下，泄漏了吗？如果泄漏，泄漏了多少个goroutine?

不进行resp.Body.Close()，泄漏是一定的，读写加main是13个，是不对的

因为http。Get的DefaultTransport 

一次建立连接，就会启动一个读goroutine和写goroutine。这就是为什么一次http.Get()会泄漏两个goroutine的来源

虽然执行了 6 次循环，而且每次都没有执行 Body.Close() ,就是因为执行了ioutil.ReadAll()把内容都读出来了，连接得以复用，因此只泄漏了一个读goroutine和一个写goroutine，最后加上main goroutine，所以答案就是3个goroutine。
从另外一个角度说，正常情况下我们的代码都会执行 ioutil.ReadAll()，但如果此时忘了 resp.Body.Close()，确实会导致泄漏。但如果你调用的域名一直是同一个的话，那么只会泄漏一个 读goroutine 和一个写goroutine，这就是为什么代码明明不规范但却看不到明显内存泄漏的原因

### goroutine泄露问题

如果你启动了一个 goroutine，但并没有符合预期的退出，直到程序结束，此goroutine才退出，这种情况就是 goroutine 泄露。当 goroutine 泄露发生时，该 goroutine 的栈(一般 2k 内存空间起)一直被占用不能释放，goroutine 里的函数在堆上申请的空间也不能被 垃圾回收器 回收。这样，在程序运行期间，内存占用持续升高，可用内存越来也少，最终将导致系统崩溃

channel引起泄漏

1.从 channel 里读，但是没有写

2.向 unbuffered channel 写，但是没有读

3.向已满的 buffered channel 写，但是没有读
解决方法，2,3设定buffer size，分配值和接收值数量一样

4.select操作在所有case上阻塞
解决方法：
使用上述实现里的模式，传入一个 quit channel，配合 select，当不需要的时候，close 这个 quit channel，该 goroutine 就可以退出
或者使用ctx包

5.goroutine进入死循环中，导致资源一直无法释放


### interface类型可以比较吗

interface类型可以比较，动态类型，动态值，两个一样就可以比较，只有slice，map无法比较，只能和nil比较，或者通过reflect包DeepEqual，或者cmp包比较

struct可以比较，但是必须是同一类型的实例值可以比较，都相等为true


### map如何顺序读取

map不能顺序读取，是因为他是无序的，想要有序读取，首先的解决的问题就是，把ｋｅｙ变为有序，所以可以把key放入切片，对切片进行排序，遍历切片，通过key取值


### 实现set

通过map实现


``` javascript
type inter interface{}

type Set struct {
    m map[inter]bool
    sync.RWMutex
}

func New() *Set {
    return &Set{
        m: map[inter]bool{},
    }
}
func (s *Set) Add(item inter) {
    s.Lock()
    defer s.Unlock()
    s.m[item] = true
}
```

### switch fullthrough

switch的每个case最后都会break

用fullthrough关键字，可以继续执行下一个case

### go的几个命令

``` javascript
go env: #用于查看go的环境变量
go run: #用于编译并运行go源码文件
go build: #用于编译源码文件、代码包、依赖包
go get: #用于动态获取远程代码包
go install: #用于编译go文件，并将编译结构安装到bin、pkg目录
go clean: #用于清理工作目录，删除编译和安装遗留的目标文件
go version: #用于查看go的版本信息
```

### go的log包线程安全 

Golang的标准库提供了log的机制，但是该模块的功能较为简单（看似简单，其实他有他的设计思路）。在输出的位置做了线程安全的保护。