---
title: GO基本数据结构：slice
date: 2020-12-21 17:56:22
tags: go
categories: GO
comments: true
description: 解析go语言，go的基本结构，slice切片
---

一个slice是一个数组某个部分的引用。在内存中，它是一个包含3个域的结构体，

分为3个部分：

1.指向slice的指针
2.slice的长度，长度是下标操作的上界，如x[i]中i必须小于长度
3.slice的容量，容量是分割操作的上界，如x[i:j]中j不能大于容量

![1](1.png)

数组的slice不是复制操作，而是一个新的数据结构，新的指针，x[1:3]它只是写了一个新的slice结构的属性来引用相同的存储数据

### slice的扩容

其实slice在Go的运行时库中就是一个
C语言动态数组的实现，
在$GOROOT/src/pkg/runtime/runtime.h中可以看到它的定义


``` javascript
struct    Slice
{    // must not move anything
    byte*    array;        // actual data
    uintgo    len;        // number of elements
    uintgo    cap;        // allocated number of elements
};
```

对slice进行append的操作时，slice会自动扩容

规则：
1、扩容后的大小是当前大小的2倍以上，则是新大小
``` javascript
if newSize >= 2* oldSize {
	size = newSize
}
```


2、如果扩容后的大小小于当前大小的2倍，则循环以下操作：
	1.当前大小小于1024,则按2倍大小增长
	2.当前大小大于1024，则按1/4倍大小增长
增长后的大小超过新大小，则结束循环

``` javascript
if newSize >= 2* oldSize {
	else {
		for {
			if oldSize > newSize {
				break
			}
			if oldSize < 1024 {
				oldSize += 2* oldSize
			} else {
				oldSize += 1/4* oldSize
			}
		}	
	}
}
```

### go协程下的slice扩容append

问题：go协程下，进行append操作，append并不是协程安全，往一个slice下添加，并发高，会出现问题

#### 方法1，索引处理

设置一个全局slice

go协程下，不进行append，而是对全局slice，利用局部索引赋值，在for循环，go协程结束后，对其进行处理

开销比较小

#### 方法2，channel

#### 方法3，加锁

对append操作进行上锁，append完进行解锁

开销比较大

``` javascript
var l sync.Mutex

l.Lock() // 加锁
a = append(a, 1)
l.Unlock() // 解锁
```

### slice添加元素

#### 追加元素

``` javascript
a = append(a, i)
```

#### 插入元素

##### 创建临时切片
取前2位，然后插入3，再把后几位加上

``` javascript
var a = []int{1,2,4,5,6}
var b= a[2:]
b = append([]int{3},b[0:]...)
a=append(a[0:2],b...)
```
##### append链式操作

``` javascript
var a = []int{1,2,4,5,6}
a=append(a[:2],append([]int{3},a[2:]...)...)
```

##### copy操作
新添加一个0，然后复制，不需要新开切片

``` javascript
var a = []int{1,2,4,5,6}
a=append(a,0)
// copy前a[3:]是[5,6,0]，a[2:]是[4,5,6,0]
// 两个长度不同进行copy，取最短长度，把后面那个值，放到前面去
// 则结果位a[3:]就是[4,5,6]
// a为[1,2,4,4,5,6]
// 最后再修改第三个值，完成插入
copy(a[3:],a[2:])
a[2]=3
```
这种方法比较高效
``` javascript
s = append(s, zero_value)
copy(s[i+1:], s[i:])
s[i] = x
```

### slice删除元素

根据下标删除元素

``` javascript
//删除元素 3 索引(下标) 3
index := 3
// 这里通过 append 方法 分成两个然后合并
// append(切片名,追加的元素) 切片名这里我们进行切割一个新的切片DelIndex[:index] 追加的元素将索引后面的元素追加
// DelIndex[index+1:]...) 为什么追加会有...三个点, 因为是一个切片 所以需要展开
DelIndex = append(DelIndex[:index], DelIndex[index+1:]...)
```

### slice反转
``` javascript
func reverse(s []byte) []byte {
	for i, j := 0, len(s)-1; i < j; i, j = i+1, j-1 {
		s[i], s[j] = s[j], s[i]
	}
	return s
}
```

``` javascript
func reverseSlice (arr []int) {
    for i := 0; i < len(arr)/2; i++ {
        arr[i], arr[len(arr)-1-i] = arr[len(arr)-1-i], arr[i] 
    }
}
```
