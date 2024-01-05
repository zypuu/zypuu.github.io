---
title: GO里的defer关键字
date: 2020-12-27 13:26:22
tags: GO
categories: GO
comments: true
description: 解析go语言，defer关键字
---
defer用于资源的释放，会在函数返回之前进行调用

``` javascript
  	f,err := os.Open(filename)
	if err != nil {
    	panic(err)
	}
	defer f.Close()
```

如果有多个defer，调用顺序类似于栈，越后面的defer表达式越先被调用

## defer使用注意

### 示例
例1：

``` javascript
  	func f() (result int) {
	    defer func() {
	        result++
	    }()
	    return 0
	}
```
正确结果返回1，而不是0

可改写成：
``` javascript
  	func f() (result int) {
	    result = 0  //return语句不是一条原子调用，return xxx其实是赋值＋ret指令
	    func() { //defer被插入到return之前执行，也就是赋返回值和ret指令之间
	        result++
	    }()
	    return
	}
```
所以返回是1

例2：
``` javascript
  	func f() (r int) {
	     t := 5
	     defer func() {
	       t = t + 5
	     }()
	     return t
	}
```
返回结果是5，不是10
可改写成：
``` javascript
  	func f() (r int) {
	     t := 5
	     r = t //赋值指令
	     func() {        //defer被插入到赋值与返回之间执行，这个例子中返回值r没被修改过
	         t = t + 5
	     }
	     return        //空的return指令
	}
```
所以结果是5

例3：
``` javascript
  	func f() (r int) {
   		defer func(r int) {
	          r = r + 5
	    }(r)
	    return 1
	}
```
结果是1，不是6

可以改写成：
``` javascript
  	func f() (r int) {
	     r = 1  //给返回值赋值
	     func(r int) {        //这里改的r是传值传进去的r，不会改变要返回的那个r值
	          r = r + 5
	     }(r)
	     return        //空的return
	}
```
所以结果是1

### 原理

return xxx这一条语句并不是一条原子指令!

函数返回的过程是这样的：先给返回值赋值，然后调用defer表达式，最后才是返回到调用函数中。

defer表达式可能会在设置函数返回值之后，在返回到调用函数之前，修改返回值，使最终的函数返回值与你想象的不一致。

## defer的实现

defer跟go类似

调用runtime.deferproc而不是runtime.newproc

在defer出现的地方，插入了指令call runtime.deferproc，然后在函数返回之前的地方，插入指令call runtime.deferreturn。

普通函数汇编

``` javascript
  	add xx SP
	return
```

defer

``` javascript
  	call runtime.deferreturn，
	add xx SP
	return
```

goroutine的控制结构中，有一张表记录defer，调用runtime.deferproc时会将需要defer的表达式记录在表中，而在调用runtime.deferreturn的时候，则会依次从defer表中出栈并执行

## for循环的defer

不建议这么使用

defer 先进后出