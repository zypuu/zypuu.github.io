---
title: GO的接口interface和反射
date: 2021-01-20 14:48:22
tags: go
categories: GO
comments: true
description: 解析go语言，go的基本结构，interface与reflect
---

## interface定义

接口是一组方法签名(声明的是一组方法的集合)。当一个类型为接口中的所有方法提供定义时，它被称为实现该接口

示例：
``` javascript

type Animal interface {
    Speak() string
}

type Dog struct {
}
 
func (d Dog) Speak() string {
    return "Woof!"
}
 
type Cat struct {
}
 
func (c Cat) Speak() string {
    return "Meow!"
}

func main() {
    animals := []Animal{Dog{}, Cat{}}
    for _, animal := range animals {
        fmt.Println(animal.Speak())
    }
}
```

### 空interface{}

interface{} 类型，空接口，没有方法的接口，所有类型都至少实现了 0 个方法，所以 所有类型都实现了空接口

``` javascript
func DoSomething(v interface{}) {
   // ...
}
```
v是interface类型，其他类型需要转换断言

### 指针和接口

上面的Cat的speak方法是值接收器，下面的改为指针接收器
``` javascript
func (c *Cat) Speak() string {
    return "Meow!"
}
```
这时访问需要指针类型定义才可以访问，不然会报错
``` javascript
animals := []Animal{new(Dog), new(Cat)}
```
这种方式下Dog也可以正常工作，因为一个指针类型可以通过其相关的值类型来访问值类型的方法，但是反过来不行。即，一个 * Dog 类型的值可以使用定义在 Dog 类型上的 Speak() 方法，而 Cat 类型的值不能访问定义在 * Cat 类型上的方法


## interface实现

interface实际上就是一个结构体，包含两个成员。其中一个成员是指向具体数据的指针，另一个成员中包含了类型信息。空接口和带方法的接口略有不同，eface 和 iface

### eface

``` javascript
struct Eface
{
    Type*    type;
    void*    data;
};
```
eface 表示空的 interface{}，它用两个机器字长表示，第一个字 type 是指向实际类型描述的指针，第二个字 data 代表数据指针

### iface

``` javascript
struct Iface
{
    Itab*    tab;
    void*    data;
};
```
iface 表示至少带有一个函数的 interface， 它也用两个机器字长表示，第一个字 tab 指向一个 itab 结构，第二个字 data 代表数据指针

### data

data 用来保存实际变量的地址。

data 中的内容会根据实际情况变化，因为 golang 在函数传参和赋值时是 值传递 的，所以：

1.如果实际类型是一个值，那么 interface 会保存这个值的一份拷贝。interface 会在堆上为这个值分配一块内存，然后 data 指向它。

2.如果实际类型是一个指针，那么 interface 会保存这个指针的一份拷贝。由于 data 的长度恰好能保存这个指针的内容，所以 data 中存储的就是指针的值。它和实际数据指向的是同一个变量。

### type
type 类型结构如下，反射方法会涉及到type域
``` javascript
struct Type
{
    uintptr size; // 为该类型所占用的字节数量
    uint32 hash;
    uint8 _unused;
    uint8 align;
    uint8 fieldAlign;
    uint8 kind; // 表示类型的种类，如 bool、int、float、string、struct、interface 等。
    Alg *alg;
    void *gc; // 精确的垃圾回收中，就是依赖Type结构体中的gc域的
    UncommonType *x;
    Type *ptrto;
};
```

### Itab

Iface和Eface略有不同，它是带方法的interface底层使用的数据结构。data域同样是指向原始数据的，而Itab的结构如下

``` javascript
struct    Itab
{
    InterfaceType*    inter;
    Type*    type;
    Itab*    link;
    int32    bad;
    int32    unused;
    void    (*fun[])(void);
};
```

1.inter 指向对应的 interface 的类型信息。

2.type 和 eface 中的一样，指向的是实际类型的描述信息 type

3.fun 为函数列表，表示对于该特定的实际类型而言，interface中所有函数的地址，一个Iface中的具体类型中实现的方法会被拷贝到Itab的fun数组中

### Itab函数生成

假设 interface 有 m 个函数， struct 有 n 个函数，那么 itab 中的函数表生成的时间复杂度为 O(m* n) 

遍历 interface 的所有函数，对每次迭代都从 struct 中遍历找到匹配的函数

Type结构体中是有个UncommonType字段的，里面有张方法表，类型所实现的方法都在里面。而在Itab中有个InterfaceType字段，这个字段中也有一张方法表，就是这个接口所要求的方法。

这两处方法表都是排序过的，只需要一遍顺序扫描进行比较，应该可以知道Type中否实现了接口中声明的所有方法，所以实现了 O(m + n) 时间复杂度的算法


### interface参数传递与函数调用

``` javascript
type Binary uint64

func (i Binary) String() string {
    return strconv.FormatUint(uint64(i), 10)
}

type Stringer interface {
    String() string
}

func test(s Stringer) {
    s.String()
}

func main() {
    a := Binary(0x123)
    test(a)
}
```


1.分配一块内存 p， 并且将对象 a 的内容拷贝到 p 中

2.创建 iface 对象 i，将 i.tab 赋值为 itab<Stringer, Binary>。将 i.data 赋值为 p

3.使用 i 作为参数调用 test 函数。

4.当 test 函数执行 s.String 时，实际上就是在 s.tab 的 fun 中索引（索引由编译器在编译时生成）到 String 函数，并且调用它

## 反射

不知道类型的情况下，可更新变量、运行时查看值、调用方法以及直接对他们的布局进行操作的机制，称为反射

比如需要一个函数处理各种类型的值：
``` javascript
switch value := value.(type) {
case string:
	// ...一些操作
case int:	
	// ...一些操作	
case cbsStruct: // 自定义的结构体	
	// ...一些操作

// ...
}
```

类型很多，代码会很长，且不好维护

反射可以获取变量的内部信息，reflect包是用来实现运行反射的。通过reflect包能够完成对一个interface{}变量的具体类型以及值的获取

### reflect.Type和reflect.Value

``` javascript
reflect.ValueOf()
```
获取输入参数接口中的数据的值，如果为空则返回0 <- 注意是0

``` javascript
reflect.TypeOf()
```
动态获取输入参数接口中的值的类型，如果为空则返回nil <- 注意是nil

输出了interface{}的真实类型以及真实值

### Kind

也是代表类型

``` javascript
type order struct {  
    ordId      int
    customerId int
}

o := order{
    ordId:      456,
    customerId: 56,
}

t := reflect.TypeOf(q)
k := t.Kind(q)
```

reflect.Type和reflect.Kind
Type代表interface{}实际类型main.order
而Kind代表具体类型struct

### NumField() 和Field()

NumField()方法获取一个struct所有的fields，Field(i int)获取指定第i个field的reflect.Value
``` javascript
 v := reflect.ValueOf(q) // TypeOf 也可以
for i := 0; i < v.NumField(); i++ {
    fmt.Printf("Field:%d type:%T value:%v\n", i, v.Field(i), v.Field(i))
}
```

### Int() 和String()
Int()和String()主要用于从reflect.Value提取对应值作为int64和string类型
``` javascript
 reflect.ValueOf(a).Int()
 reflect.ValueOf(b).String()
```

### Name()
.Name()可以获取去这个类型的名称
``` javascript
 reflect.TypeOf(a).Name()
```

### NumMethod()和Method()
可以获取struct的方法
``` javascript
t := reflect.TypeOf(s)
 for i:=0;i<t.NumMethod(); i++ {
	m := t.Method(i)
	fmt.Printf("第%d个方法是：%s:%v\n", i+1, m.Name, m.Type)
}
```

### 反射创建
``` javascript
type People struct {
    Age   int
    Name  string
    Test1 string
    Test2 string
}

func NewUseReflect() interface{} {
    var p People
    t := reflect.TypeOf(p)
    v := reflect.New(t)
    v.Elem().Field(0).Set(reflect.ValueOf(18))
    v.Elem().Field(1).Set(reflect.ValueOf("shiina"))
    v.Elem().Field(2).Set(reflect.ValueOf("test1"))
    v.Elem().Field(3).Set(reflect.ValueOf("test2"))
    return v.Interface()
}
```

golang的反射性能很差
