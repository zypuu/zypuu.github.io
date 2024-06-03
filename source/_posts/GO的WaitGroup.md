---
title: GO的WaitGroup
date: 2024-04-20 11:02:20
tags: GO
categories: GO
comments: true
description: GO的WaitGroup用法，以及源码分析，以及使用注意事项
---

Go语言中的WaitGroup类似Java的CountDownLatch，任务检查点，任务等待点，比如有一个主任务，执行到某一时刻需要执行两个子任务，主任务等待阻塞，两个子任务执行完毕后再执行主任务，这就需要一个任务阻塞检查点，等待子任务执行完毕



### WaitGroup使用

示例：

```go
	wg.Add(1)
	go createRand()

	wg.Add(1)
	go sumResult()
	wg.Wait()
	for v := range resultChan {
		j := (*v).job
		s := (*v).sum
		fmt.Println("1111", j, s)
	}
```

创建两个协程方法，产生随机数，计算结果，主线程等待计算结果后，再打印结果

一共有三个方法

```
(wg *WaitGroup) Add(delta int)
(wg *WaitGroup) Done()
(wg *WaitGroup) Wait()
```

`Add` 方法用于设置 WaitGroup 的计数值，可以理解为子任务的数量

`Done` 方法用于将 WaitGroup 的计数值减一，可以理解为完成一个子任务

`Wait` 方法用于阻塞调用者，直到 WaitGroup 的计数值为0，即所有子任务都完成



### 源码分析

#### WaitGroup结构

```go
type WaitGroup struct {
    noCopy noCopy // noCopy 字段标识，由于 WaitGroup 不能复制，方便工具检测
    state1 [3]uint32  // 12个字节，8个字节标识 计数值和等待数量，4个字节用于标识信号量
}
```

state1 是个复合字段，会拆分为两部分： 64位（8个字节）的 statep 作为一个整体用于原子操作, 其中前面4个字节表示计数值，后面四个字节表示等待数量；剩余 32位（4个字节）semap 用于标识信号量。

Go语言中对于64位的变量进行原子操作，需要保证该变量是 64位对齐 的，也就是要保证这 8个字节 的首地址是 8 的整数倍。因此当 state1 的首地址是 8 的整数倍时，取前8个字节作为 statep ，后4个字节作为 semap；当 state1 的首地址不是 8 的整数倍时，取后8个字节作为 statep ，前4个字节作为 semap。

```go
func (wg *WaitGroup) state() (statep *uint64, semap *uint32) {
    // 首地址是8的倍数时，前8个字节为 statep, 后四个字节为 semap
    if uintptr(unsafe.Pointer(&wg.state1))%8 == 0 {
        return (*uint64)(unsafe.Pointer(&wg.state1)), &wg.state1[2]
    } else { 
        
    // 后8个字节为 statep, 前四个字节为 semap  
        return (*uint64)(unsafe.Pointer(&wg.state1[1])), &wg.state1[0]
    }
}
```

#### Add

```go
func (wg *WaitGroup) Add(delta int) {

    // 拿到计数值等待者变量 statep 和 信号量 semap
    statep, semap := wg.state()

    // 计数值加上 delta: statep 的前四个字节是计数值，因此将 delta 前移 32位
    state := atomic.AddUint64(statep, uint64(delta)<<32)

    // 计数值
    v := int32(state >> 32)

    // 等待者数量
    w := uint32(state)

    // 如果加上 delta 之后，计数值变为负数，不合法，panic
    if v < 0 {
        panic("sync: negative WaitGroup counter")
    }

    // delta > 0 && v == int32(delta) : 表示从 0 开始添加计数值
    // w!=0 ：表示已经有了等待者
    // 说明在添加计数值的时候，同时添加了等待者，非法操作。添加等待者需要在添加计数值之后
    if w != 0 && delta > 0 && v == int32(delta) {
        panic("sync: WaitGroup misuse: Add called concurrently with Wait")
    }

    // v>0 : 计数值不等于0，不需要唤醒等待者，直接返回
    // w==0: 没有等待者，不需要唤醒，直接返回
    if v > 0 || w == 0 {
        return
    }

    // 再次检查数据是否一致
    if *statep != state {
        panic("sync: WaitGroup misuse: Add called concurrently with Wait")
    }

    // 到这里说明计数值为0，且等待者大于0，需要唤醒所有的等待者，并把系统置为初始状态（0状态）
  
  // 将计数值和等待者数量都置为0
    *statep = 0

    // 唤醒等待者
    for ; w != 0; w-- {
        runtime_Semrelease(semap, false, 0)
    }
}
```

#### Done

```go
// 完成一个任务，将计数值减一，当计数值减为0时，需要唤醒所有的等待者
func (wg *WaitGroup) Done() {
    wg.Add(-1)
}
```

Add 方法用于添加一个计数值（负数相当于减），当计数值变为0后， Wait 方法阻塞的所有等待者都会被释放，计数值变为负数是非法操作，产生 panic，当计数值为0时（初始状态），Add 方法不能和 Wait 方法并发调用，需要保证 Add 方法在 Wait 方法之前调用，否则会 panic

#### Wait

```go
// 调用 Wait 方法会被阻塞，直到 计数值 变为0
func (wg *WaitGroup) Wait() {

    // 获取计数、等待数和信号量
    statep, semap := wg.state()

    for {
        state := atomic.LoadUint64(statep)

        // 计数值
        v := int32(state >> 32)

        // 等待者数量
        w := uint32(state)

        // 计数值数量为0，直接返回，无需等待
        if v == 0 {
            return
        }

        // 到这里说明计数值数量大于0
        // 增加等待者数量：这里会有竞争，比如多个 Wait 调用，或者在同时调用 Add 方法，增加不成功会继续 for 循环
        if atomic.CompareAndSwapUint64(statep, state, state+1) {
            // 增加成功后，阻塞在信号量这里，等待被唤醒
            runtime_Semacquire(semap)

            // 被唤醒的时候，应该是0状态。如果重用 WaitGroup，需要等 Wait 返回
            if *statep != 0 {
                panic("sync: WaitGroup is reused before previous Wait has returned")
            }
            return
        }
    }
}
```

### 注意事项

根据源码分析，我们可以得到如何使用waitGroup可以避免panic：

1、保证 Add 在 Wait 前调用

2、Add 中不传递负数

3、任务完成后不要忘记调用 Done 方法，建议使用 defer wg.Done()

4、不要复制使用 WaitGroup，函数传递时使用指针传递

5、尽量不复用 WaigGroup，减少出问题的风险

