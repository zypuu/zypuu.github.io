---
title: GO基本数据结构：nil,指针,值,引用类型
date: 2020-12-24 16:29:22
tags: GO
categories: GO
comments: true
description: 解析go语言，go的基本结构，nil,指针，值，引用类型
---

## 引用类型，值

1.值类型：变量直接存储，内存通常在栈中分配。
2.引用类型：变量存储的是一个地址，这个地址存储最终的值。内存通常在堆上分配。通过GC回收

PS : 通常在函数中转入指针效率比较高，因为方法中的参数是需要进行拷贝的，拷贝指针的效率比较高，要是一个大的结构体的话拷贝的效率就比较低

1.值类型 ： 基本数据类型int、float、bool、string以及数组和struct。
2.引用类型：指针、slice、map、chan等都是引用类型

## nil，初始化零值

nil代表空值

布尔类型是false
整型是0
字符串是""
而指针，函数，interface，slice，channel和map的零值都是nil

PS： 
string的空值是""，它是不能跟nil比较的。即使是空的string，它的大小也是两个机器字长的。
slice也类似，它的空值并不是一个空指针，而是结构体中的指针域为空，空的slice的大小也是三个机器字长的。

指针域为空，但是有长度域，所以不是nil

## 指针

指针指的是内存地址，而指针本身也是有内存地址的

&： 取址符
变量获取内存地址，需要在变量前加上一个符号&
* ：取值符
内存地址获取变量，需要在内存地址前加上一个符号*

这俩做着相反的事

指针的值：指的是数据的内存地址
指针的地址：指的是指针本身的内存地址

变量赋值后，指针不变

一个值为nil的指针变量，直接赋值会出问题

如下所示，声明的是一个指向string的指针类型的变量
前面打印的&a是取的指针本身的地址，后面打印的是指针的值，也就是空值nil，还没有被赋值成地址，跟空字符串不一样

``` javascript

func main(){
    // 声明一个指针变量 a 其类型也是 string
    var a *string
    fmt.Printf("aPot: %p %#v\n", &a, a) // 输出 a: 0xc42000c030 (*string)(nil)
    *a = "This is a Pointer"  // 报错：panic: runtime error: invalid memory address or nil pointer dereference
}
```
所以不能这样赋值，读取也会报错。* a 做取值操作会panic

解决方法是初始化内存
``` javascript
var b string
a = &b
*a = "This is a Pointer"
```
给a赋值一个b的内存地址，在通过取值* 相当于从这个内存地址取了一个空字符串，再赋值，就不会报错
