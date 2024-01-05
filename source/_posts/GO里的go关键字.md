---
title: GO里的go关键字
date: 2020-12-27 11:30:22
tags: GO
categories: GO
comments: true
description: 解析go语言，go关键字
---

go f(x, y, z)会启动一个新的goroutine运行函数f(x, y, z)。函数f，变量x、y、z的值是在原goroutine计算的，只有函数f的执行是在新的goroutine中的

新的goroutine不能和当前go线程用同一个栈，否则会相互覆盖。

所以对go关键字的调用协议与普通函数调用是不同的

普通函数的调用协议

``` javascript
  	MOVL    $1, 0(SP)
    MOVL    $2, 4(SP)
    MOVL    $3, 8(SP)
    CALL    f(SB)
```

将参数 1，2，3进栈，然后调用函数f

go 关键字调用函数

``` javascript
  	MOVL    $1, 0(SP)
    MOVL    $2, 4(SP)
    MOVL    $3, 8(SP)
    PUSHQ   $f(SB)
    PUSHQ   $12
    CALL    runtime.newproc(SB)
    POPQ    AX
    POPQ    AX
```
前半部分一样，将参数1，2，3进栈，同时也将函数f进栈，12也进栈，12是函数参数的大小

调用runtime.newproc函数

runtime.newproc函数接受的参数分别是：参数大小，新的goroutine是要运行的函数，函数的n个参数

runtime.newproc函数中

1.新建一个栈空间，将栈参数的12个字节拷贝到新栈空间中并让栈指针指向参数
2.线程状态有点像当被调度器剥夺CPU后一样，寄存器PC、SP会被保存到类似于进程控制块的一个结构体struct G内
3.f被存放在了struct G的entry域，后面进行调度器恢复goroutine的运行，新线程将从f开始执行。


