---
title: GO的内存分配
date: 2021-01-06 13:48:22
tags: go
categories: GO
comments: true
description: 解析go语言，go的内存分配
---



``` javascript
go tool compile -S main.go
```
通过以上查看汇编代码可以看到内存申请情况，runtime.newobject是用于申请内存的内建函数，newobject是mallocgc的代理，mallocgc是管理堆内存的函数。Go分配内存有两种策略：小块内存申请和大块内存申请


## 内存管理基本结构

golang的内存管理如下：

![1](1.png)

### MSpan

内存管理的基本单位是MSpan。MSpan是一个表示若干连续内存页（8KB）的数据结构

``` javascript
    struct MSpan
    {
        PageID    start;        // starting page number
        uintptr    npages;        // number of pages in span
    };
```
基地址+(页号* 页大小)，就可以定位到这个MSpan的实际的地址空间
PS：连续页，PageID是起始id，npages是数量

每个 mspan按照它自身的属性 SizeClass的大小分割成若干个 object，每个 object可存储一个对象

Size_Class = Span_Class / 2

这是因为其实每个 SizeClass有两个 mspan，也就是有两个 SpanClass。其中一个分配给含有指针的对象，另一个分配给不含有指针的对象，每个等级SizeClass会存在两份mspan链表：一个链表用于存储内部不包含指针的对象，另一个链表用于存储内部包含指针的对象。这么的好处是垃圾回收时更高效，因为不需要扫描不包含指针的那个mspan链表

mspan按大小被划分为大约67个等级的object，大小从8字节到32K字节不等，不同等级存储不同大小的object内存块

``` javascript
const _NumSizeClasses = 67
var class_to_size = [_NumSizeClasses]uint16{0, 8, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 256, 288, 320, 352, 384, 416, 448, 480, 512, 576, 640, 704, 768, 896, 1024, 1152, 1280, 1408, 1536,1792, 2048, 2304, 2688, 3072, 3200, 3456, 4096, 4864, 5376, 6144, 6528, 6784, 6912, 8192, 9472, 9728, 10240, 10880, 12288, 13568, 14336, 16384, 18432, 19072, 20480, 21760, 24576, 27264, 28672, 32768}
```

比如 SizeClass等于3， object大小就是32B。 32B大小的object可以存储对象大小范围在17B到32B的对象。而对于微小对象（小于16B），分配器会将其进行合并，将几个对象分配到同一个 object中

最大的数是32768，也就是32KB，超过此大小就是大对象了，要直接从mheap堆上分配

对于mspan来说，它的 SizeClass会决定它所能分到的页数，这也是写死在代码里的：


``` javascript
// path: /usr/local/go/src/runtime/sizeclasses.go
const _NumSizeClasses = 67
var class_to_allocnpages = [_NumSizeClasses]uint8{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 3, 2, 3, 1, 3, 2, 3, 4, 5, 6, 1, 7, 6, 5, 4, 3, 5, 7, 2, 9, 7, 5, 8, 3, 10, 7, 4}

```

比如当我们要申请一个 object大小为 32B的 mspan的时候，在classtosize里对应的索引是3，而索引3在 class_to_allocnpages数组里对应的页数就是1，即为8KB

一个 mspan的 SizeClass等于10，根据前面的 class_to_size数组，得出这个 msapn分割的 object大小是144B，算出可分配的对象个数是 8KB/144B=56.89个，取整56个，所以会有一些内存浪费掉了，Go的源码里有所有 SizeClass的 mspan浪费的内存的大小；再根据 class_to_allocnpages数组，得到这个 mspan只由1个 page组成；假设这个 mspan是分配给无指针对象的，那么 spanClass等于20


### MHeap分配堆

代表Go程序持有的所有堆空间，Go程序使用一个 mheap的全局对象 mheap来管理堆内存

MHeap层次用于直接分配较大(>32kB)的内存空间，以及给MCentral和MCache等下层提供空间

mheap主要用于大对象的内存分配，以及管理未切割的 mspan，用于给 mcentral切割成小对象

mheap中含有所有规格的 mcentral，所以，当一个 mcache从 mcentral申请 mspan时，只需要在独立的 mcentral中使用锁，并不会影响申请其他规格的 mspan

``` javascript
   //path: /usr/local/go/src/runtime/mheap.go
	type mheap struct {
		lock mutex
		// spans: 指向mspans区域，用于映射mspan和page的关系
		spans []*mspan
		// 指向bitmap首地址，bitmap是从高地址向低地址增长的
		bitmap uintptr
		// 指示arena区首地址
		arena_start uintptr
		// 指示arena区已使用地址位置
		arena_used uintptr
		// 指示arena区末地址
		arena_end uintptr
		central [67*2]struct {
			mcentral mcentral
			pad [sys.CacheLineSize - unsafe.Sizeof(mcentral{})%sys.CacheLineSize]byte
		}
	}
```

### MCentral

为所有 mcache提供切分好的 mspan资源。每个 central保存一种特定大小的全局 mspan列表，包括已分配出去的和未分配出去的。 每个 mcentral对应一种 mspan，而 mspan的种类导致它分割的 object大小不同。当工作线程的 mcache中没有合适（也就是特定大小的）的 mspan时就会从 mcentral获取

MCentral被所有的工作线程共同享有，存在多个Goroutine竞争的情况，因此会消耗锁资源


``` javascript
    struct MCentral
    {
        Lock;
        int32 sizeclass;
        MSpan nonempty;
        MSpan empty;
        int32 nfree;
    };
```

每个维护了两张全局的mspan链表。一张链表为non-empty类型，包含了可供分配的mspan（由于一个span可能包含多个object，只要有一个或一个以上的object可供分配即表示该mspan可供分配），一张为empty类型，包含已分配完毕的mspan

1.获取 加锁；从 nonempty链表找到一个可用的 mspan；并将其从 nonempty链表删除；将取出的 mspan加入到 empty链表；将 mspan返回给工作线程；解锁。
2.归还 加锁；将 mspan从 empty链表删除；将 mspan加入到 nonempty链表；解锁

PS：当Go执行垃圾回收时，如果span中的内存块被标记为可供分配，span会重新加入到non-empty链表中

![3](3.png)

当mcentral中也没有可供分配的span时，Go会从堆上申请新的span并将其放入mcentral中进行切分


### MCache本地小块内存

对于32KB以下的小块内存申请，Go会从本地缓存mcache中获取内存。

每一个M都有一个自己的局部内存缓存MCache，这样分配小对象的时候直接从MCache中分配，就不用加锁了，这是Go能够在多线程环境中高效地进行内存分配的重要原因

MCache是mspan切分后的列表，包含object的列表，提供可使用的内存，2倍的object列表，上面mspan已经提到过

![2](2.png)

mcache在初始化的时候是没有任何 mspan资源的，在使用过程中会动态地从 mcentral申请，之后会缓存下来。当对象小于等于32KB大小时，使用 mcache的相应规格的 mspan进行分配。

如果mcache上没有空闲的内存块可供分配该怎么办，则进入下一级mcentral

### OS

堆在必要时向操作系统申请内存。它会申请一块大内存，被称为arena，在64位系统下为64MB，其它大部分系统为4MB，申请的内存同样用span管理， 1M打底

![4](4.png)

![5](5.png)

arena：堆区，运行时该区域每8KB会被划分成一个页，存储了所有在堆上初始化的对象

bitmap：标识arena中哪些地址保存了对象，bitmap中一个字节的内存对应arena区域中4个指针大小的内存，并标记了是否包含指针和是否扫描的信息（一个指针大小为8B，因此bitmap的大小为512GB/(4* 8)=16GB）

spans：存放mspan的指针，其中每个mspan会包含多个页，spans中一个指针（8B）表示arena中某一个page（8KB），因此spans的大小为512GB/(1024)=512MB


## 内存分配流程

Go的内存分配器在分配对象时，根据对象的大小，分成三类：小对象（小于等于16B）、一般对象（大于16B，小于等于32KB）、大对象（大于32KB）

1.>32KB 的对象，直接从mheap上分配

2.<=16B 的对象使用mcache的tiny分配器分配

3.(16B,32KB] 的对象，首先计算对象的规格大小，然后使用mcache中相应规格大小的mspan分配

4.如果mcache没有相应规格大小的mspan，则向mcentral申请

5.如果mcentral没有相应规格大小的mspan，则向mheap申请

6.如果mheap中也没有合适大小的mspan，则向操作系统申请


## 总结

1.Go在程序启动时，会向操作系统申请一大块内存，之后自行管理（仅仅是虚拟的地址空间，并不会真正分配内存）。

2.Go内存管理的基本单元是mspan，它由若干个页组成，每种mspan可以分配特定大小的object。

3.mcache, mcentral, mheap是Go内存管理的三大组件，层层递进。
mcache管理线程在本地缓存的mspan；
mcentral管理全局的mspan供所有线程使用；
mheap管理Go的所有动态分配内存。

4.极小对象会分配在一个object中，以节省资源，使用tiny分配器分配内存；一般小对象通过mspan分配内存；大对象则直接由mheap分配内存