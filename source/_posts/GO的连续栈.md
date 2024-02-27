---
title: GO的连续栈
date: 2020-12-28 10:38:20
tags: 内存
categories: GO
comments: true
description: 解析go语言，go的连续栈，go协程，栈空间不足的处理，自动增长
---


Go语言支持goroutine，每个goroutine需要能够运行，所以它们都有自己的栈

所以栈的空间是随着需要自动增长的，每个goroutine开始只分配很小的栈空间

所以开了千万个goroutine也不会耗尽内存

continuous stack

## 基本原理

1.调用栈默认大小是4K（1.7修改为2K），最大栈1G，超出将panic
2.每次执行函数调用时，runtime就会进行检测，当前栈的大小不够用，会触发中断
3.runtime会保存此时函数运行的上下文
4.分配一个新的足够大的栈空间，进行2倍指数扩容将旧栈的内容拷贝到新栈中，并做一些设置，使得当函数恢复运行时，函数会在新分配的栈中继续执行

### 捕获栈空间不足，实行中断

1.比较栈指针寄存器和G结构体的stackguard
2.SP大于g->stackguard，runtime.morestack(保存M，连接旧栈新栈)，runtime.newstack(新栈)

每个goroutine对应一个结构体G，大致相当于进程控制块的概念
结构体中存了stackbase和stackguard，用于确定这个goroutine使用的栈空间信息
如果栈指针寄存器(SP)值超越了stackguard就需要扩展栈空间

汇编如下：
``` javascript
000000 00000 (test.go:3)    TEXT    "".main+0(SB),$0-0
000000 00000 (test.go:3)    MOVQ    (TLS),CX
0x0009 00009 (test.go:3)    CMPQ    SP,(CX)
0x000c 00012 (test.go:3)    JHI    ,21
0x000e 00014 (test.go:3)    CALL    ,runtime.morestack00_noctxt(SB)
0x0013 00019 (test.go:3)    JMP    ,0
0x0015 00021 (test.go:3)    NOP    ,
```
如果SP大于g->stackguard了，则会调用runtime.morestack函数.开始中断，新建栈空间

runtime.morestack是用汇编实现的，做的事情大致是将一些信息存在M结构体中，这些信息包括当前栈桢，参数，当前函数调用，函数返回地址（两个返回地址，一个是runtime.morestack的函数地址，一个是f的返回地址）。通过这些信息可以把新栈和旧栈链起来

``` javascript
void runtime.morestack() {
    if(g == g0) {
        panic();
    } else {
        m->morebuf.gobuf_pc = getCallerCallerPC();
        void *SP = getCallerSP();
        m->morebuf.gobuf_sp = SP;
        m->moreargp = SP;
        m->morebuf.gobuf_g = g;
        m->morepc = getCallerPC();

        void *g0 = m->g0;
        g = g0;
        setSP(g0->g_sched.gobuf_sp);
        runtime.newstack();
    }
}
```
然后调用runtime.newstack，建立新的栈空间

PS：newstack是切换到m->g0的栈中去调用的。m->g0是调度器栈，go的运行时库的调度器使用的都是m->g0。

### 旧栈数据复制到新栈

1.runtime.morestack会调用于runtime.newstack
2.newstack：分配一个足够大的新的空间，将旧的栈中的数据复制到新的栈中

复制数据的过程中要考虑指针失效问题

某个指针引用旧栈的地址，搬到新栈后，旧栈会被释放，指针失效

所以要修改指针地址：

1.当前栈帧之前的每一个栈帧，对其中的每一个指针，检测指针指向的地址
2.如果指向地址是落在旧栈范围内的，则将它加上一个偏移使它指向新栈的相应地址。这个偏移值等于新栈基地址减旧栈基地址。

恢复运行：
1.切换到当前g
2.runtime.oldstack从过去保存旧栈的信息拿到相关信息
3.runtime.gogo根据旧的信息恢复上下文，运行

整个过程就完成了。

## 流程

1.比较SP与g的stackguard，SP大于g->stackguard，开始连续栈扩容
2.调用runtime.morestack，主要功能是保存当前的栈的一些信息
3.调用runtime.newstack，函数的主要功能是分配空间，装饰此空间，复制数据到新空间，修改指针
4.gogocall的方式切换到新分配的栈，获取旧的信息，恢复上下文，继续运行

栈缩容：是在垃圾回收的里处理的，当检测到栈只使用了不到1/4时，栈缩小为原来的1/2