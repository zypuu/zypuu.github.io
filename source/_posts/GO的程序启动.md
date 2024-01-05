---
title: GO的程序启动
date: 2020-12-29 10:12:20
tags: GO
categories: GO
comments: true
description: 解析go语言，go的程序启动流程
---

启动流程大致如下：


``` javascript
_rt0_amd64_darwin   # 通过参数argc和argv等，确定栈的位置，得到寄存器

main  # 跳转到本文件main，继续执行

_rt0_amd64  # 设置好m->g0的栈,将当前的SP设置为stackbase,将SP往下大约64K的地方设置为stackguard,然后会获取处理器信息,然后设置本地线程存储

runtime.check # 检测像int8,int16,float等是否是预期的大小，检测cas操作是否正常

runtime.args # 去 stack 里读取参数和环境变量，执行文件的绝对路径初始化

runtime.osinit # 初始化OS:获取CPU数量和内存页大小初始化

runtime.hashinit # 使用读/dev/urandom的方式从内核获得随机数种子

runtime.schedinit # 初始化调度，命令行参数、环境变量、gc、栈空间、内存管理、所有P实例、HASH算法等初始化

runtime.newproc # 创建一个goruntine并执行，执行函数为 runtime.main

runtime.mstart # 启动这个m，即m0，里面会调用schedule函数进入调度状态

main.main # 用户的main函数

runtime.exit

```

## 本地线程存储

每个goroutine都有自己的控制信息，这些信息是存放在一个结构体G中

有一个全局变量g是结构体G的指针，我们希望只有唯一的全局变量g，保证全局唯一，而不是g0，g1，g2

每个线程访问它，得到自己线程的G，这种情况下就需要本地线程存储。

g确实是一个全局变量，却在不同线程有多份不同的副本。每个goroutine去访问g时，都是对应到自己线程的这一份副本


## 调度器初始化

注释写在代码里，大概流程如下：

``` javascript
func schedinit() {
	// raceinit must be the first call to race detector.
	// In particular, it must be done before mallocinit below calls racemapshadow.
	// 从TLS中获取g实例
    _g_ := getg()

    if raceenabled {
        _g_.racectx, raceprocctx0 = raceinit()
    }

    // 设置全局线程数上限
    sched.maxmcount = 10000

    // 初始化一系列函数所在的PC计数器，用于traceback
    tracebackinit()
    // 貌似是验证链接器符号的正确性
    moduledataverify()
    // 栈的初始化
    stackinit()
    // 内存分配器初始化
    mallocinit()
    mcommoninit(_g_.m)
    // 初始化AES HASH算法
    alginit()       // maps must not be used before this call
    modulesinit()   // provides activeModules
    typelinksinit() // uses maps, activeModules
    itabsinit()     // uses activeModules

    msigsave(_g_.m)
    initSigmask = _g_.m.sigmask

    // 获取命令行参数
    // 例如: ./$GOPATH/test/main test1 test2
    // 执行goargs得到runtime.argslice = []string len: 3, cap: 3, ["main","test1","test2"]
    goargs()
    // 获取所有的环境变量
    goenvs()
    parsedebugvars()
    // gc初始化
    gcinit()

    sched.lastpoll = uint64(nanotime())

    // P个数检查
    procs := ncpu
    if n, ok := atoi32(gogetenv("GOMAXPROCS")); ok && n > 0 {
        procs = n
    }
    if procs > _MaxGomaxprocs {
        procs = _MaxGomaxprocs
    }
	// 所有P的初始化
    if procresize(procs) != nil {
        throw("unknown runnable goroutine during bootstrap")
    }

    if buildVersion == "" {
        // Condition should never trigger. This code just serves
        // to ensure runtime·buildVersion is kept in the resulting binary.
        buildVersion = "unknown"
    }
}

```