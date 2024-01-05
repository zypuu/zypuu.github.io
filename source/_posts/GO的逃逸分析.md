---
title: GO的逃逸分析
date: 2021-01-08 09:46:22
tags: GO
categories: GO
comments: true
description: 解析go语言，go的逃逸分析，变量内存分配
---

## 关于堆栈及变量分配

在函数内部定义了一个局部变量，然后返回这个局部变量的地址（指针）。这些局部变量是在栈上分配的（静态内存分配），一旦函数执行完毕，变量占据的内存会被销毁，任何对这个返回值作的动作（如解引用），都将扰乱程序的运行，甚至导致程序直接崩溃

即时通过函数内部使用new函数构造一个变量（动态内存分配），然后返回此变量的地址。因为变量是在堆上创建的，所以函数退出时不会被销毁，但是new出来的对象不delete，也会发生内存泄漏


栈分配开销小，堆分配开销大。

栈空间会随着一个函数的结束自动释放，堆空间需要 GC 模块不断的跟踪扫描回收

``` javascript
func stack() int { 
    // 变量 i 会在栈上分配
     i := 10
     return i
}
func heap() *int {
    // 变量 j 会在堆上分配
    j := 10
    return &j

```

stack 函数中的变量 i 在函数退出会自动释放；而 heap 函数返回的是对变量i的引用，也就是说 heap()退出后，表示变量 i 还要能被访问，它会自动被分配到堆空间上

汇编代码如下，可以查看汇编代码
``` javascript
go tool compile -S main.go
```

``` javascript
TEXT main.stack(SB) /tmp/test.go
  test.go:7     0x487240        48c74424080a000000  MOVQ $0xa, 0x8(SP)  
  test.go:7     0x487249        c3          RET         
 
TEXT main.heap(SB) /tmp/test.go
  test.go:9     0x487250        64488b0c25f8ffffff  MOVQ FS:0xfffffff8, CX          
  test.go:9     0x487259        483b6110        CMPQ 0x10(CX), SP           
  test.go:9     0x48725d        7639            JBE 0x487298                
  test.go:9     0x48725f        4883ec18        SUBQ $0x18, SP              
  test.go:9     0x487263        48896c2410      MOVQ BP, 0x10(SP)           
  test.go:9     0x487268        488d6c2410      LEAQ 0x10(SP), BP           
  test.go:10        0x48726d        488d05ac090100      LEAQ 0x109ac(IP), AX            
  test.go:10        0x487274        48890424        MOVQ AX, 0(SP)              
  test.go:10        0x487278        e8f33df8ff      CALL runtime.newobject(SB)      
  test.go:10        0x48727d        488b442408      MOVQ 0x8(SP), AX            
  test.go:10        0x487282        48c7000a000000      MOVQ $0xa, 0(AX)            
  test.go:11        0x487289        4889442420      MOVQ AX, 0x20(SP)           
  test.go:11        0x48728e        488b6c2410      MOVQ 0x10(SP), BP           
  test.go:11        0x487293        4883c418        ADDQ $0x18, SP              
  test.go:11        0x487297        c3          RET                 
  test.go:9     0x487298        e8a380fcff      CALL runtime.morestack_noctxt(SB)   
  test.go:9     0x48729d        ebb1            JMP main.heap(SB)           
// ...
 
TEXT runtime.newobject(SB) /usr/share/go/src/runtime/malloc.go
  malloc.go:1067    0x40b070        64488b0c25f8ffffff  MOVQ FS:0xfffffff8, CX          
  malloc.go:1067    0x40b079        483b6110        CMPQ 0x10(CX), SP           
  malloc.go:1067    0x40b07d        763d            JBE 0x40b0bc                
  malloc.go:1067    0x40b07f        4883ec28        SUBQ $0x28, SP              
  malloc.go:1067    0x40b083        48896c2420      MOVQ BP, 0x20(SP)           
  malloc.go:1067    0x40b088        488d6c2420      LEAQ 0x20(SP), BP           
  malloc.go:1068    0x40b08d        488b442430      MOVQ 0x30(SP), AX           
  malloc.go:1068    0x40b092        488b08          MOVQ 0(AX), CX              
  malloc.go:1068    0x40b095        48890c24        MOVQ CX, 0(SP)              
  malloc.go:1068    0x40b099        4889442408      MOVQ AX, 0x8(SP)            
  malloc.go:1068    0x40b09e        c644241001      MOVB $0x1, 0x10(SP)         
  malloc.go:1068    0x40b0a3        e888f4ffff      CALL runtime.mallocgc(SB)       
  malloc.go:1068    0x40b0a8        488b442418      MOVQ 0x18(SP), AX           
  malloc.go:1068    0x40b0ad        4889442438      MOVQ AX, 0x38(SP)           
  malloc.go:1068    0x40b0b2        488b6c2420      MOVQ 0x20(SP), BP           
  malloc.go:1068    0x40b0b7        4883c428        ADDQ $0x28, SP              
  malloc.go:1068    0x40b0bb        c3          RET                 
  malloc.go:1067    0x40b0bc        e87f420400      CALL runtime.morestack_noctxt(SB)   
  malloc.go:1067    0x40b0c1        ebad            JMP runtime.newobject(SB)
```

 上面的汇编中可看到，heap() 函数调用了 runtime.newobject() 方法，它会调用 mallocgc 方法从 mcache 上申请内存。堆内存分配不仅分配上逻辑比栈空间分配复杂，它最致命的是会带来很大的管理成本，Go 语言要消耗很多的计算资源对其进行标记回收（也就是 GC 成本）

## 逃逸分析

### 什么是逃逸分析

在编译原理中，分析指针动态范围的方法称之为逃逸分析。通俗来讲，当一个对象的指针被多个方法或线程引用时，我们称这个指针发生了逃逸。

逃逸分析决定一个变量是分配在栈上，还是分配在堆上

golang即时用new分配的内存，函数返回后，没有用了，就丢到栈上

如果还有函数外部其他引用，就会分配到堆上，实现按需分配

### 为什么要逃逸分析

如果变量都分配到堆上，堆不像栈可以自动清理。它会引起Go频繁地进行垃圾回收，而垃圾回收会占用比较大的系统开销（占用CPU容量的25%）。

堆和栈相比，堆适合不可预知大小的内存分配。但是为此付出的代价是分配速度较慢，而且会形成内存碎片。栈内存分配则会非常快

通过逃逸分析，可以尽量把那些不需要分配到堆上的变量直接分配到栈上，堆上的变量少了，会减轻分配堆内存的开销，同时也会减少gc的压力，提高程序的运行速度

### 如何逃逸分析

以下命令可以查看逃逸分析
``` javascript
go build -gcflags '-m -l' test.go
go tool compile "-m" main.go
```

Go逃逸分析最基本的原则是：如果一个函数返回对一个变量的引用，那么它就会发生逃逸。

Go 编辑器会自动帮我们找出需要进行动态分配的变量，它是在编译时追踪一个变量的生命周期，如果能确认一个数据只在函数空间内访问，不会被外部使用，则使用栈空间，否则就要使用堆空间

简单来说，编译器会根据变量是否被外部引用来决定是否逃逸：

1.如果函数外部没有引用，则优先放到栈中，定义了一个很大的数组，需要申请的内存过大，超过了栈的存储能力，也会分配到堆中
2.如果函数外部存在引用，则必定放到堆中

``` javascript
package main

import "fmt"

func foo() *int {
    t := 3
    return &t;
}

func main() {
    x := foo()
    fmt.Println(*x)
}
```
分析如下：
``` javascript
# command-line-arguments
src/main.go:7:9: &t escapes to heap
src/main.go:6:7: moved to heap: t
src/main.go:12:14: *x escapes to heap
src/main.go:12:13: main ... argument does not escape
```
x也发生了逃逸

PS：有些函数参数为interface类型，比如
fmt.Println(a...interface{})，编译期间很难确定其参数的具体类型，也会发生逃逸

### 逃逸分析注意点

不要盲目使用变量的指针作为函数参数，虽然它会减少复制操作。但其实当参数为变量自身的时候，复制是在栈上完成的操作，开销远比变量逃逸后动态地在堆上分配内存少的多。

PS：不要以为使用了堆内存就一定会导致性能低下，使用栈内存会带来性能优势。因为实际项目中，系统的性能瓶颈一般都不会出现在内存分配上。千万不要盲目优化，找到系统瓶颈，用数据驱动优化。

### 逃逸分析缺陷问题

编译器有时会将不需要使用堆空间的变量，也逃逸掉。这里是容易出现性能问题的大坑

多级间接赋值容易导致逃逸

这里的多级间接指的是，对某个引用类对象中的引用类成员进行赋值。Go 语言中的引用类数据类型有 func, interface, slice, map, chan, * Type(指针)

公式 Data.Field = Value，
如果 Data, Field 都是引用类的数据类型，
则会导致 Value 逃逸。这里的等号 = 不单单只赋值，也表示参数传递

例子：
``` javascript
[]interface{}: data[0] = 100 会导致 100 逃逸

map[string]interface{}: data["key"] = "value" 会导致 "value" 逃逸

map[interface{}]interface{}: data["key"] = "value" 会导致 key 和 value 都逃逸

map[string][]string: data["key"] = []string{"hello"} 会导致切片逃逸

map[string]*int: 赋值时 *int 会 逃逸

[]*int: data[0] = &i 会使 i 逃逸

func(*int): data(&i) 会使 i 逃逸

func([]string): data([]{"hello"}) 会使 []string{"hello"} 逃逸

chan []string: data <- []string{"hello"} 会使 []string{"hello"} 逃逸
```

#### 函数变量逃逸
``` javascript

func test(i int)        {}
func testEscape(i *int) {}
 
func main() {
    i, j, m, n := 0, 0, 0, 0
    t, te := test, testEscape // 函数变量
 
    // 直接调用
    test(m)        // 不逃逸
    testEscape(&n) // 不逃逸
    // 间接调用
    t(i)   // 不逃逸
    te(&j) // 逃逸
}
```

#### 间接赋值

``` javascript

type Data struct {
    data  map[int]int
    slice []int
    ch    chan int
    inf   interface{}
    p     *int
}
 
func main() {
    d1 := Data{}
    d1.data = make(map[int]int) // GOOD: does not escape
    d1.slice = make([]int, 4)   // GOOD: does not escape
    d1.ch = make(chan int, 4)   // GOOD: does not escape
    d1.inf = 3                  // GOOD: does not escape
    d1.p = new(int)             //  GOOD: does not escape
 
    d2 := new(Data)             // d2 是指针变量， 下面为该指针变量中的指针成员赋值
    d2.data = make(map[int]int) // BAD: escape to heap
    d2.slice = make([]int, 4)   // BAD:  escape to heap
    d2.ch = make(chan int, 4)   // BAD:  escape to heap
    d2.inf = 3                  // BAD:  escape to heap
    d2.p = new(int)             // BAD:  escape to heap
}
```

#### interface

只要使用了 Interface 类型(不是 interafce{})，那么赋值给它的变量一定会逃逸

``` javascript

type Iface interface {
    Dummy()
}
type Integer int
func (i Integer) Dummy() {}
 
func main() {
    var (
        iface Iface
        i     Integer
    )
    iface = i
    iface.Dummy() //  make i escape to heap
    // 形成 iface.Dummy.i = i
}

```

#### channel

``` javascript


func test() {
    var (
        chInteger   = make(chan *int)
        chMap       = make(chan map[int]int)
        chSlice     = make(chan []int)
        chInterface = make(chan interface{})
        a, b, c, d  = 0, map[int]int{}, []int{}, 32
    )
    chInteger <- &a  // 逃逸
    chMap <- b       // 逃逸
    chSlice <- c     // 逃逸
    chInterface <- d // 逃逸
}

```

向 channel 中发送数据，本质上就是为 channel 内部的成员赋值，就像给一个 slice 中的某一项赋值一样。所以 chan * Type, chan map[Type]Type, chan []Type, chan interface{} 类型都会导致发送到 channel 中的数据逃逸。

这本来也是情理之中的，发送给 channel 的数据是要与其他函数分享的，为了保证发送过去的指针依然可用，只能使用堆分配。

#### 可变参数

可变参数如 func(arg ...string) 实际与 func(arg []string) 是一样的，会增加一层访问路径。这也是 fmt.Sprintf 总是会使参数逃逸的原因


``` javascript
package main

func a (args ...interface{}) int {
	c := args[0].(int)
	d := args[1].(int)
	return c + d
}
 
func main() {
    res := a(1, 2) // 1, 2逃逸
}


```

#### 结构体方法

以下 2 种很常规的写法，但他们却有着很大的性能差距

``` javascript

type User struct {
    roles []string
}
 
func (u *User) SetRoles(roles []string) {
    u.roles = roles
}
 
func SetRoles(u User, roles []string) User {
    u.roles = roles
    return u
}

func main() {
	var b User

	a := SetRoles(b, []string{"1", "2"}) // // 参数[]string{"1", "2"} 不逃逸

	b.SetRoles([]string{"1", "2"}) // 参数[]string{"1", "2"} 逃逸
}


```
两种情况下

第一种没有逃逸

``` javascript
第一种 a := SetRoles(b, []string{"1", "2"})

main.go:8:6: can inline (*User).SetRoles
main.go:12:6: can inline SetRoles
main.go:17:6: can inline main
main.go:20:15: inlining call to SetRoles
main.go:8:25: leaking param: roles
main.go:8:7: (*User).SetRoles u does not escape
main.go:12:15: leaking param: u to result ~r2 level=0
main.go:12:23: leaking param: roles to result ~r2 level=0
main.go:20:27: main []string literal does not escape
main.go:20:2: a declared and not used

```

第二种逃逸，第二种开销会比较大

``` javascript
第二种 b.SetRoles([]string{"1", "2"})

main.go:8:6: can inline (*User).SetRoles
main.go:12:6: can inline SetRoles
main.go:17:6: can inline main
main.go:22:12: inlining call to (*User).SetRoles
main.go:8:25: leaking param: roles
main.go:8:7: (*User).SetRoles u does not escape
main.go:12:15: leaking param: u to result ~r2 level=0
main.go:12:23: leaking param: roles to result ~r2 level=0
main.go:22:21: []string literal escapes to heap
main.go:22:3: main b does not escape

```