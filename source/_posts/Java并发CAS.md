---
title: Java并发CAS
date: 2023-04-15 11:45:00
tags: 多线程并发
categories: Java
comments: true
description: 关于java并发CAS机制，源码，优点，缺点，java8对于CAS的优化
---



## 什么是CAS

Compare And Swap，比较并交换，是一条CPU的并发原语，CAS操作对应的CPU指令是CMPXCHG（Compare and Exchange）指令。CMPXCHG指令是一种原子指令，用于比较内存中的值与一个寄存器中的值，如果相等，则将新的值存入内存中；如果不相等，则不执行任何操作。这个操作是原子的，即在执行过程中不会被中断，由操作系统保证。

CAS是一种无锁的原子算法



## 核心机制

主内存中存放的共享变量的值：V（一般情况下这个V是内存的地址值，通过这个地址可以获得内存中的值）

工作内存中共享变量的副本值，也叫预期值：A

需要将共享变量更新到的最新值：B

![1](1.jpg)

步骤：

1. 获取当前共享变量的值和期望值：
   CAS操作的第一步是获取共享变量的当前值V，同时也需要提供一个期望值A，这个期望值是用来比较共享变量的当前值是否与之相等的基准。
2. 比较共享变量的当前值V和期望值A是否相等：
   在这一步，CAS会比较共享变量的当前值和之前提供的期望值是否相等。如果相等，说明共享变量的值符合预期，可以进行下一步操作。
3. 更新共享变量的值B：
   如果共享变量的当前值与期望值相等，CAS会将共享变量的值更新为要写入的新值。这个操作是原子性的，即在这个过程中不会有其他线程对该共享变量进行干扰。
4. 处理失败的情况：
   如果共享变量的当前值V与期望值A不相等，说明此时有其他线程已经修改了共享变量的值BV。在这种情况下，当前线程需要重新获取共享变量的最新值，并重新执行步骤2和3，直至操作成功。

## 乐观锁的典型实现

悲观锁更新的方式认为：在更新数据的时候大概率会有其他线程去争夺共享资源，所以悲观锁的做法是：第一个获取资源的线程会将资源锁定起来，其他没争夺到资源的线程只能进入阻塞队列，等第一个获取资源的线程释放锁之后，这些线程才能有机会重新争夺资源。synchronized就是java中悲观锁的典型实现，synchronized使用起来非常简单方便，但是会使没争抢到资源的线程进入阻塞状态，线程在阻塞状态和Runnable状态之间切换效率较低（比较慢）。比如你的更新操作其实是非常快的，这种情况下你还用synchronized将其他线程都锁住了，线程从Blocked状态切换回Runnable华的时间可能比你的更新操作的时间还要长。

乐观锁更新方式认为:在更新数据的时候其他线程争抢这个共享变量的概率非常小，所以更新数据的时候不会对共享数据加锁。但是在正式更新数据之前会检查数据是否被其他线程改变过，如果未被其他线程改变过就将共享变量更新成最新值，如果发现共享变量已经被其他线程更新过了，就重试，直到成功为止。CAS机制就是乐观锁的典型实现



## Java Unsafe类底层实现

底层依靠Unsafe的CAS实现，以AtomicInteger为例

```
/** 
 * Atomically adds the given value to the current value. 
 * 
 * @param delta the value to add 
 * @return the previous value 
 */ 
public final int getAndAdd(int delta) { 
    return unsafe.getAndAddInt(this, valueOffset, delta); 
} 
public final int incrementAndGet() { 
    for (;;) { 
        int current = get(); 
        int next = current + 1; 
        if (compareAndSet(current, next)) 
            return next; 
    } 
} 
private volatile int value; 
public final int get() { 
    return value; 
}
```

代码是一个无限循环，也就是CAS的自旋。循环体当中做了三件事：

获取当前值;

当前值+1，计算出目标值;

进行CAS操作，如果成功则跳出循环(当前值和目标值相等)，如果失败则重复上述步骤;

```
public final int getAndAddInt(Object var1, long var2, int var4) { 
    int var5; 
    do { 
        var5 = this.getIntVolatile(var1, var2); 
    } while (!this.compareAndSwapInt(var1, var2, var5, var5 + var4));//native方法 
    return var5; 
}    
******** 
public final native boolean compareAndSwapInt(Object var1, long var2, int var4, int var5);//底层c++实现 
```



可以看到compareAndSwapInt为native方法，对应底层hotspot虚拟机unsage.cpp，最终调用了Atomic::cmpxchg来保证原子性

```
UNSAFE_ENTRY(jboolean, Unsafe_CompareAndSwapInt(JNIEnv *env, jobject unsafe, jobject obj, jlong offset, jint e, jint x)) 
  UnsafeWrapper("Unsafe_CompareAndSwapInt"); 
  oop p = JNIHandles::resolve(obj); 
  jint* addr = (jint *) index_oop_from_field_offset_long(p, offset); 
  return (jint)(Atomic::cmpxchg(x, addr, e)) == e; 
UNSAFE_END 
*** 
```

Atomic::cmpxchg针对不同平台有不同的实现方式

```
*** 
// Adding a lock prefix to an instruction on MP machine 
#define LOCK_IF_MP(mp) "cmp $0, " #mp "; je 1f; lock; 1: " 
*** 
inline jint     Atomic::cmpxchg    (jint     exchange_value, volatile jint*     dest, jint     compare_value) { 
  int mp = os::is_MP(); 
  __asm__ volatile (LOCK_IF_MP(%4) "cmpxchgl %1,(%3)" 
                    : "=a" (exchange_value) 
                    : "r" (exchange_value), "a" (compare_value), "r" (dest), "r" (mp) 
                    : "cc", "memory"); 
  return exchange_value; 
} 
```

最重要的指令为 LOCK_IF_MP ， MP是指多CPU(multi processors)，最终意义为多CPU的情况下需要lock，通过lock的方式来保证原子;

lock解释：

1、确保后续指令执行的原子性;

2、在Pentium及之前的处理器中，带有lock前缀的指令在执行期间会锁住总线，使得其它处理器暂时无法通过总线访问内存，很显然，这个开销很大。在新的处理器中，Intel使用缓存锁定来保证指令执行的原子性，缓存锁定将大大降低lock前缀指令的执行开销;

3、禁止该指令与前面和后面的读写指令重排序;

4、把写缓冲区的所有数据刷新到内存中;

总之：JAVA中我们使用到涉及到CAS操作的底层实现为对应平台虚拟机中的c++代码(lock指令)实现来保证原子性;

## 问题及缺点

### ABA

#### 问题

因为CAS需要在操作值的时候检查下值有没有发生变化，如果没有发生变化则更新，但是如果一个值原来是A，变成了B，又变成了A， 那么使用CAS进行检查时会发现它的值没有发生变化，但是实际上却变化了

对于基本类型的值来说，这种把数字改变了在改回原来的值是没有太大影响的，但如果是对于引用类型的话，就会产生很大的影响了

#### 解决

为了解决这个 ABA 的问题，我们可以引入版本控制，例如，每次有线程修改了引用的值，就会进行版本的更新，虽然两个线程持有相同的引用，但他们的版本不同，这样，我们就可以预防 ABA 问题了。Java 中提供了 AtomicStampedReference 这个类，就可以进行版本控制了。

### 循环时间长，开销大

#### 问题

在并发量比较高的情况下，如果许多线程反复尝试更新某一个变量，即自旋CAS如果长时间不成功，会给CPU带来非常大的执行开销;

#### 解决

如果JVM能支持处理器提供的pause指令，那么效率会有一定的提升。

pause指令有两个作用，第一它可以延迟流水线执行指令(de-pipeline),使CPU不会消耗过多的执行资源，延迟的时间取决于具体实现的版本，在一些处理器上延迟时间是零。

第二它可以避免在退出循环的时候因内存顺序冲突(memory order violation)而引起CPU流水线被清空(CPU pipeline flush)，从而提高CPU的执行效率;

代码层面，破坏掉for死循环，当自旋超过一定时间或者一定次数时，return退出;

使用类似ConcurrentHashMap的方法。当多个线程竞争时，将粒度变小，将一个变量拆分为多个变量，达到多个线程访问多个资源的效果，最后再调用sum把它合起来，能降低CPU消耗，但是治标不治本;

### 只能保证一个共享变量的原子操作

#### 问题

只能保证一个共享变量的原子操作：当对一个共享变量执行操作时，我们可以使用循环CAS的方式来保证原子操作，但是对多个共享变量操作时，循环CAS就无法保证操作的原子性;

#### 解决

1、合并变量

2、AtomicReference类来保证引用对象之间的原子性，你可以把多个变量放在一个对象里来进行CAS操作

## 优点

可以保证变量操作的原子性；

并发量不是很高的情况下，使用CAS机制比使用锁机制效率更高；

在线程对共享资源占用时间较短的情况下，使用CAS机制效率也会较高



## Java8对 CAS 的优化

为了解决上面的第二个问题，线程较多时候，大量线程的自旋浪费CPU资源

Java8 引入了一个 cell[] 数组，它的工作机制是这样的：假如有 5 个线程要对 i 进行自增操作，由于 5 个线程的话，不是很多，起冲突的几率较小，那就让他们按照以往正常的那样，采用 CAS 来自增吧。

但是，如果有 100 个线程要对 i 进行自增操作的话，这个时候，冲突就会大大增加，系统就会把这些线程分配到不同的 cell 数组元素去，假如 cell[10] 有 10 个元素吧，且元素的初始化值为 0，那么系统就会把 100 个线程分成 10 组，每一组对 cell 数组其中的一个元素做自增操作，这样到最后，cell 数组 10 个元素的值都为 10，系统在把这 10 个元素的值进行汇总，进而得到 100，二这，就等价于 100 个线程对 i 进行了 100 次自增操作

原理就是：采用了分段 CAS + 自动分段迁移机制优化了线程较多且竞争激烈的 CAS 并发性能。如上述所讲，比如 LongAdder ，内部包含了一个数组，数组中每个元素都是一个独立的子计数器。当多个线程同时操作时，线程会随机落在数组中的子计数器上进行 CAS 操作，避免了大量线程同时操作一个计数器的尴尬局面！最后获取的最终值，是通过自动分段合并计算出主计数器的值



## 使用时机

线程数较少、等待时间短可以采用自旋锁进行CAS尝试拿锁，较于synchronized高效;

线程数较大、等待时间长，不建议使用自旋锁，占用CPU较高;