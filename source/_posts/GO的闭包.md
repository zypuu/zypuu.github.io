---
title: GO的闭包
date: 2020-12-28 14:07:20
tags: go
categories: GO
comments: true
description: 解析go语言，go的闭包
---

闭包=函数+引用环境

``` javascript
func f(i int) func() int {
    return func() int {
        i++
        return i
    }
}
```

函数f返回了一个函数，返回的这个函数，返回的这个函数就是一个闭包。这个函数中本身是没有定义变量i的，而是引用了它所在的环境（函数f）中的变量i

将闭包函数表现为一个结构体
``` javascript
type Closure struct {
    F func()()  // 函数
    i *int      // 参数
}
```

底层汇编上，确实闭包是一个结构体

``` javascript
func f(i int) func() int {
    return func() int {
        i++
        return i
    }
}


MOVQ    $type.int+0(SB),(SP)
PCDATA    $0,$16
PCDATA    $1,$0
CALL    ,runtime.new(SB)    // 是不是很熟悉，这一段就是i = new(int)    
...    
MOVQ    $type.struct { F uintptr; A0 *int }+0(SB),(SP)    // 这个结构体就是闭包的类型
...
CALL    ,runtime.new(SB)    // 接下来相当于 new(Closure)
PCDATA    $0,$-1
MOVQ    8(SP),AX
NOP    ,
MOVQ    $"".func·001+0(SB),BP
MOVQ    BP,(AX)                // 函数地址赋值给Closure的F部分
NOP    ,
MOVQ    "".&i+16(SP),BP        // 将堆中new的变量i的地址赋值给Closure的值部分
MOVQ    BP,8(AX)
MOVQ    AX,"".~r1+40(FP)
ADDQ    $24,SP
RET    ,
```

返回闭包时并不是单纯返回一个函数，而是返回了一个结构体，记录下函数返回地址和引用的环境中的变量地址