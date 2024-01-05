---
title: GO的基本数据结构：map
date: 2020-12-23 16:14:22
tags: GO
categories: GO
comments: true
description: 解析go语言，go的基本类型 map
---

## 基本数据结构

G基本结构如下，runtime/map.go go版本 v1.11

``` javascript
// A header for a Go map.
type hmap struct {
        // Note: the format of the hmap is also encoded in cmd/compile/internal/gc/reflect.go.
        // Make sure this stays in sync with the compiler's definition.
        count     int // # live cells == size of map.  Must be first (used by len() builtin)
        flags     uint8
        B         uint8  // log_2 of # of buckets (can hold up to loadFactor * 2^B items)
        noverflow uint16 // approximate number of overflow buckets; see incrnoverflow for details
        hash0     uint32 // hash seed

        buckets    unsafe.Pointer // array of 2^B Buckets. may be nil if count==0.
        oldbuckets unsafe.Pointer // previous bucket array of half the size, non-nil only when growing
        nevacuate  uintptr        // progress counter for evacuation (buckets less than this have been evacuated)

        extra *mapextra // optional fields
}

```

1.这个hash结构使用的是一个可扩展哈希的算法，由hash值mod当前hash表大小决定某一个值属于哪个桶，而hash表大小是2的指数，即上面结构体中的2^B。

2.每次扩容，会增大到上次大小的两倍。结构体中有一个buckets和一个oldbuckets是用来实现增量扩容的。正常情况下直接使用buckets，而oldbuckets为空。如果当前哈希表正在扩容中，则oldbuckets不为空，并且buckets大小是oldbuckets大小的两倍

捅结构：
``` javascript
// A bucket for a Go map.
type bmap struct {
        // tophash generally contains the top byte of the hash value
        // for each key in this bucket. If tophash[0] < minTopHash,
        // tophash[0] is a bucket evacuation state instead.
        tophash [bucketCnt]uint8
        // Followed by bucketCnt keys and then bucketCnt values.
        // NOTE: packing all the keys together and then all the values together makes the
        // code a bit more complicated than alternating key/value/key/value/... but it allows
        // us to eliminate padding which would be needed for, e.g., map[int64]int8.
        // Followed by an overflow pointer.
}
```

每个桶bucket最多存放8个kv对，多于8个，会申请一个新的bucket，并将它与之前的bucket链起来

当两个不同的 key 落在同一个桶中，也就是发生了哈希冲突。冲突的解决手段是用链表法：在 bucket 中，从前往后找到第一个空位。这样，在查找某个 key 时，先找到对应的桶，再去遍历 bucket 中的 key


## map的增量扩容

扩容过程中会有两张表，oldtable 旧哈希表， newtable 新哈希表

1.根据结构设置，哈希表的大小是2^B，扩容之后的大小为2^(B+1)，每次扩容都变为原来大小的两倍

2.会建立一个新的2倍大小的hash表，将旧的buckets搬到新表

3.一般旧表hash值不等于新表hash，需要重新计算hash到新表，旧的表的buckets不会删除，加一个已删除标记

4.增量扩容，不会一次完成，每次搬移1-2个键值对，由于这个工作是逐渐完成的，这样就会导致一部分数据在old table中，一部分在new table中，所以对于hashmap的insert,remove,lookup操作的处理逻辑产生影响。只有当所有的bucket都从旧表移到新表之后，才会将oldbucket释放掉

PS： 为什么是增量， 为了缩短map容器的响应时间，元素很多的话，不增量就会卡住，响应时间过长

5.扩容因子：如果grow的太频繁，会造成空间的利用率很低，如果很久才grow，会形成很多的overflow buckets，查找的效率也会下降

作者测试：6.5适中，table中元素的个数大于table中能容纳的元素的个数


## map的查找过程

1、将key的类型选用hash算法得到key的hash值

2、hash值的的低位，作为buckets数组的index索引，用于找到key所在的bucket数组

3.hash的高8位存储到tophash，tophash在bucket结构里

PS：存储过程中，key放在一起。value放在一起，方便字节对齐（底层cpu访问数据效率）避免浪费存储空间

部分代码： mapaccess1方法
``` javascript
    // 不同类型 key 使用的 hash 算法在编译期确定
    alg := t.key.alg
    // 计算哈希值，并且加入 hash0 引入随机性
    hash := alg.hash(key, uintptr(h.hash0))
    // 比如 B=5，那 m 就是31，二进制是全 1
    // 求 bucket num 时，将 hash 与 m 相与，
    // 达到 bucket num 由 hash 的低 8 位决定的效果
    m := bucketMask(h.B)
    // b 就是 bucket 的地址
    b := (*bmap)(add(h.buckets, (hash&m)*uintptr(t.bucketsize)))
    // oldbuckets 不为 nil，说明发生了扩容
    if c := h.oldbuckets; c != nil {
        // 如果不是同 size 扩容（看后面扩容的内容）
        // 对应条件 1 的解决方案
        if !h.sameSizeGrow() {
            // 新 bucket 数量是老的 2 倍
            m >>= 1
        }
        // 求出 key 在老的 map 中的 bucket 位置
        oldb := (*bmap)(add(c, (hash&m)*uintptr(t.bucketsize)))
        // 如果 oldb 没有搬迁到新的 bucket
        // 那就在老的 bucket 中寻找
        if !evacuated(oldb) {
            b = oldb
        }
    }
    // 计算出高 8 位的 hash
    // 相当于右移 56 位，只取高8位
    top := tophash(hash)
    //开始寻找key
    for ; b != nil; b = b.overflow(t) {
        // 遍历 8 个 bucket
        for i := uintptr(0); i < bucketCnt; i++ {
            // tophash 不匹配，继续
            if b.tophash[i] != top {
                continue
            }
            // tophash 匹配，定位到 key 的位置
            k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
            // key 是指针
            if t.indirectkey {
                // 解引用
                k = *((*unsafe.Pointer)(k))
            }
            // 如果 key 相等
            if alg.equal(key, k) {
                // 定位到 value 的位置
                v := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.valuesize))
                // value 解引用
                if t.indirectvalue {
                    v = *((*unsafe.Pointer)(v))
                }
                return v
            }
        }
    }
    return unsafe.Pointer(&zeroVal[0])
}
```

查找流程：

1、先找oldtable，旧的hash表，如果hash表已经被添加删除标记，则去新的找

2.先比较key的hash值高8位在tophash[i]值是否相等，顺序比较，得到i

3.找到key的hash低位对应的bucket

4.如果相等则再比较bucket的第i个的key与所给的key是否相等

5.如果没有，则在overflow里继续寻找，桶溢出链表

![1](1.png)


## map的插入过程

1.初始化校验，根据key计算hash，根据低位找对对应的buckets数组

部分代码：
``` javascript
func mapassign(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
    //判断 hmap 是否已经初始化（是否为 nil）
    if h == nil {
        panic(plainError("assignment to entry in nil map"))
    }
    //...
    //判断是否并发读写 map，若是则抛出异常
    if h.flags&hashWriting != 0 {
        throw("concurrent map writes")
    }
    //根据 key 的不同类型调用不同的 hash 方法计算得出 hash 值
    alg := t.key.alg
    hash := alg.hash(key, uintptr(h.hash0))
    //设置 flags 标志位，表示有一个 goroutine 正在写入数据。因为 alg.hash 有可能出现 panic 导致异常
    h.flags |= hashWriting
    //判断 buckets 是否为 nil，若是则调用 newobject 根据当前 bucket 大小进行分配
    //初始化时没有初始 buckets，那么它在第一次赋值时就会对 buckets 分配
    if h.buckets == nil {
        h.buckets = newobject(t.bucket) // newarray(t.bucket, 1)
    }   
}
```

2.根据table中元素的个数，判断是否正在扩容。

3.如果在扩容中：
    oldbucket是被冻结的，查找时会在oldbucket中查找，但不会在oldbucket中插入数据。如果在oldbucket是找到了相应的key，做法是将它迁移到新bucket后加入evalucated标记

4.在bucket中，查找空闲的位置，如果已经存在需要插入的key，更新其对应的value。

5.如果对应的bucket已经full，重新申请新的bucket作为overbucket。

6.将key/value pair插入到bucket中

部分代码：
``` javascript
//根据低八位计算得到 bucket 的内存地址
    bucket := hash & bucketMask(h.B)
    //判断是否正在扩容，若正在扩容中则先迁移再接着处理
    if h.growing() {
        growWork(t, h, bucket)
    }
    //计算并得到 bucket 的 bmap 指针地址
    b := (*bmap)(unsafe.Pointer(uintptr(h.buckets) + bucket*uintptr(t.bucketsize)))
    //计算 key hash 高八位用于查找 Key
    top := tophash(hash)
    var inserti *uint8
    var insertk unsafe.Pointer
    var val unsafe.Pointer
    for {
        //迭代 buckets 中的每一个 bucket（共 8 个）
        for i := uintptr(0); i < bucketCnt; i++ {
            //对比 bucket.tophash 与 top（高八位）是否一致
            if b.tophash[i] != top {
                //若不一致，判断是否为空槽
                if b.tophash[i] == empty && inserti == nil {
                    //有两种情况，第一种是没有插入过。第二种是插入后被删除
                    inserti = &b.tophash[i]
                    insertk = add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
                    //把该位置标识为可插入 tophash 位置,这里就是第一个可以插入数据的地方
                    val = add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.valuesize))
                }
                continue
            }
            //若是匹配（也就是原本已经存在），则进行更新。最后跳出并返回 value 的内存地址
            k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
            if t.indirectkey {
                k = *((*unsafe.Pointer)(k))
            }
            if !alg.equal(key, k) {
                continue
            }
            // already have a mapping for key. Update it.
            if t.needkeyupdate {
                typedmemmove(t.key, k, key)
            }
            val = add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.valuesize))
            goto done
        }
        //判断是否迭代完毕，若是则结束迭代 buckets 并更新当前桶位置
        ovf := b.overflow(t)
        if ovf == nil {
            break
        }
        b = ovf
    }
    //若满足三个条件：触发最大 LoadFactor 、存在过多溢出桶 overflow buckets、没有正在进行扩容。就会进行扩容动作（以确保后续的动作）
    if !h.growing() && (overLoadFactor(h.count+1, h.B) || tooManyOverflowBuckets(h.noverflow, h.B)) {
        hashGrow(t, h)
        goto again // Growing the table invalidates everything, so try again
    }

```

PS：
插入是数据追加方式：
1.先找到对应的key，则更新对应的value并结束遍历

2.先找到对应的空位，则直接在这个位置插入，后面的都会覆盖并结束遍历，因为是顺序遍历，buckets数组后面的会被覆盖掉

3.然后就是只要在某个bucket中找到第一个空位，就会将key/value插入到这个位置。也就是位置位于bucket前面的会覆盖后面的(类似于存储系统设计中做删除时的常用的技巧之一，直接用新数据追加方式写，新版本数据覆盖老版本数据)

不过这也意味着做删除时必须完全的遍历bucket所有溢出链，将所有的相同key数据都删除。

所以目前map的设计是为插入而优化的，删除效率会比插入低一些


## map的删除过程

删除某个key的操作与分配类似，由于hashmap的存储结构是数组+链表，所以真正删除key仅仅是将对应的slot设置为empty，并没有减少内存

delete(intMap, 1)

所以过程给查找类似，把tophash值设成empty，并不是真正释放内存

### 清空map

``` javascript
for k, _ := range m {
	delete(m, k)
}
```

1.map 被清空。执行完之后调用len函数，结果肯定是0；
2.内存没有释放。清空只是修改了一个标记，底层内存还是被占用了；
3.循环遍历了len(m)次。上面的代码每一次遍历都会删除一个元素，而遍历的次数并不会因为之前每次删一个元素导致减少

真正的释放内存

``` javascript
map = nil
```

这之后坐等垃圾回收器回收就好了。

PS：用 map 做缓存，而每次更新只是部分更新，更新的 key 如果偏差比较大，有可能会有内存逐渐增长而不释放的问题


## map的性能思考，调优

1.hashmap中存的是buckets数组，而不是指针，存数组的好处：可以一次性分配更多内存，减少分配次数，避免多次gc
缺点就是，扩容时会对整个数组的值拷贝，而不是指针，代价相比指针较大

2.bucket的kv优化，如果kv小于128字节，则存的是kv值，否则kv就是指向真实kv数据的指针

## map的并发安全

map的相关操作并不是协程安全的

``` javascript
c := make(map[string]string)
wg := sync.WaitGroup{}
for i := 0; i < 10; i++ {
    wg.Add(1)
    go func(n int) {
        k, v := strconv.Itoa(n), strconv.Itoa(n)
        c[k] = v
        wg.Done()
    }(i)
}
wg.Wait()
fmt.Println(c)
```

以上操作会触发协程安全错误

加锁

``` javascript
c := make(map[string]string)
wg := sync.WaitGroup{}
var lock sync.Mutex
for i := 0; i < 10; i++ {
    wg.Add(1)
    go func(n int) {
        k, v := strconv.Itoa(n), strconv.Itoa(n)
        lock.Lock()
        c[k] = v
        lock.Unlock()
        wg.Done()
    }(i)
}
wg.Wait()
fmt.Println(c)
```

sync.Map官方包


``` javascript
var m sync.Map

//写
m.Store("foo", "hello world")
m.Store("slice", []int{1, 2, 3, 4, 5, 6, 7})
m.Store("int", 123)
//读
m.Load("foo")
m.Load("slice")
m.Load("int")
//删
m.Delete("int")
```