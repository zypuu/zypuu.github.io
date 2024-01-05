---
title: GO的make和new的区别
date: 2020-12-21 17:20:22
tags: GO
categories: GO
comments: true
description: 解析go语言
---

Go有两个数据结构创建函数：new和make。两者的区别在学习Go语言的初期是一个常见的混淆点。基本的区别是new(T)返回一个* T，返回的这个指针可以被隐式地消除引用（图中的黑色箭头）。而make(T, args)返回一个普通的T。通常情况下，T内部有一些隐式的指针（图中的灰色箭头）。一句话，new返回一个指向已清零内存的指针，而make返回一个复杂的结构。
二者都是内存的分配（堆上），但是make只用于slice、map以及channel的初始化（非零值）；而new用于类型的内存分配，并且内存置为零

![1](1.png)

## new与make

### new
new 可以开辟一个内存，然后返回这个内存的地址。

简单类型还可以初始化零值，int，string

复杂类型也可以开辟内存，初始化的是nil

nil的指针赋值会存在问题

声明一个大小为5的数组，go会自动为数组的item初始化为零值，数组可以通过索引读取和赋值。
``` javascript
var arr [5]int
fmt.Printf("arr: %p %#v \n", &arr, arr) // arr: 0xc420014180 [5]int{0, 0, 0, 0, 0} 
arr[0], arr[1] = 1, 2
fmt.Printf("arr: %p %#v \n", &arr, arr) // arr: 0xc420014180 [5]int{1, 2, 0, 0, 0}
```

如果声明的是一个数组指针，即一个指针的类型是数组
``` javascript
 var arrPot *[5]int
 fmt.Printf("arrPot: %p %#v \n", &arrPot, arrPot) // arrPot: 0xc42000c040 (*[5]int)(nil)
```
初始化的值是nil，nil是不能赋值的

我们可以new一块内存地址出来，赋给指针，这个指针取值就可以赋值了
``` javascript
var arrPot *[5]int
fmt.Printf("arrPot: %p %#v \n", &arrPot, arrPot) // arrPot: 0xc42000c040 (*[5]int)(nil) 

arrPot = new([5]int)
fmt.Printf("arrPot: %p %#v \n", &arrPot, arrPot) // arrPot: 0xc42000c040 &[5]int{0, 0, 0, 0, 0} 
(*arrPot)[0] = 11
fmt.Printf("arrPot: %p %#v \n", &arrPot, arrPot) // arrPot: 0xc42000c040 &[5]int{11, 0, 0, 0, 0}
```
### make

array是虽然是复合类型，但不是引用类型。go中的引用类似是slice，map等

声明一个map类型的变量，map不像array那样声明之后可以初始化成零值。go会给引用类型初始化为nil，nil是不能直接赋值的

map不能用new去申请内存，用make，make不仅可以开辟一个内存，还能给这个内存的类型初始化其零值，同时返回这个内存实例

make 也可以申请slice，channel

申请slice： 三个参数，第一个基本结构类型，第二个长度，第三个容量
申请map：两个参数， 第一个基本结构，第二个容量、长度

初始化需要提前申请好，防止发生扩容

