---
title: Java Map源码分析
date: 2023-03-22 19:50:00
tags: Java
categories: Java
comments: true
description: 关于java的Map， HashMap， TreeMap， ConcurrentHashMap，HashTable， TreeMap ，LinkHashMap
---



## HashMap

Java8 对 HashMap 进行了一些修改，最大的不同就是利用了红黑树，所以其由 数组+链表+红黑树 组成，

根据 hash 值我们能够快速定位到数组的具体下标，但是之后的话，需要顺着链表一个个比较下去才能找到我们需要的，时间复杂度取决于链表的长度，为 O(n)。为了降低这部分的开销，在 Java8 中，当链表中的元素超过了 8 个以后，会将链表转换为红黑树，在这些位置进行查找的时候可以降低时间复杂度为 O(logN)



源码分析详情见： [Java Set源码分析](https://zypuu.github.io/2023/02/06/Java%20Set%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/) 的HashSet部分



HashMap并非线程安全：线程不安全主要体现在resize的死循环，和使用迭代器时的Fast-Fail机制上

Fast-Fail事件机制

fail-fast 机制是java集合(Collection)中的一种错误机制。当多个线程对同一个集合的内容进行操作时，就可能会产生fail-fast事件。在使用迭代器的过程中如果HashMap被修改，那么ConcurrentModificationException将被抛出，也即Fast-fail策略。

当HashMap的iterator()方法被调用时，会构造并返回一个新的EntryIterator对象，并将EntryIterator的expectedModCount设置为HashMap的modCount（该变量记录了HashMap被修改的次数）。

在通过该Iterator的next方法访问下一个Entry时，它会先检查自己的expectedModCount与HashMap的modCount是否相等，如果不相等，说明HashMap被修改，直接抛出`ConcurrentModificationException`。该Iterator的remove方法也会做类似的检查

## ConcurrentHashMap

为了解决HashMap的并发安全问题，可以使用concurrentHashMap

### Java7实现

基于散列的Map，并不是将每个方法都在同一个锁上同步使得每次只能有一个线程访问线程，而使用一种更细粒度的加锁机制来实现更大程度的共享。这种机制称为分段锁（Lock Striping）。在这种机制中，任意数量的读取线程可以并发地访问map**，**执行读取操作的线程和执行写入操作的线程可以并发地访问map，并且一定数量的写入线程可以并发地修改map。ConcurrentHashMap带来的结果是，在并发访问的环境下将实现更高的吞吐量，而在单线程环境中只损失非常小的性能。

ConcurrentHashMap返回的迭代器具有**弱一致性**。弱一致性的迭代器可以容忍并发的修改，当创建迭代器时会遍历已有的元素，并可以（但是不保证）在迭代器被构造后将修改操作反应给容器

ConcurrentHashMap 是一个 Segment 数组，Segment 通过继承 ReentrantLock 来进行加锁，所以每次需要加锁的操作锁住的是一个 segment，这样只要保证每个 Segment 是线程安全的，也就实现了全局的线程安全。

concurrencyLevel：并行级别（Segment 的数量），默认是 16。

也就是说 ConcurrentHashMap 有 16 个 Segments，所以理论上，这个时候，最多可以同时支持 16 个线程并发写，只要它们的操作分别分布在不同的 Segment 上。

这个值可以在初始化的时候设置为其他值，但是一旦初始化以后，它是不可以扩容的

![1](1.jpg)



#### put方法

```
 public V put(K key, V value) {
      Segment<K,V> s;
      if (value == null)
          throw new NullPointerException();
      // 1. 计算 key 的 hash 值
      int hash = hash(key);
      // 2. 根据 hash 值找到 Segment 数组中的位置 j
      //    hash 是 32 位，无符号右移 segmentShift(28) 位
      //    然后和 segmentMask(15) 做一次与操作，也就是说 j 是 hash 值的最后 4 位，也就是槽的数组下标
     int j = (hash >>> segmentShift) & segmentMask;
     // 刚刚说了，初始化的时候初始化了 segment[0]，但是其他位置还是 null，
     // ensureSegment(j) 对 segment[j] 进行初始化
     if ((s = (Segment<K,V>)UNSAFE.getObject          // nonvolatile; recheck
          (segments, (j << SSHIFT) + SBASE)) == null) //  in ensureSegment
         s = ensureSegment(j);
     // 3. 插入新值到 槽 s 中
     return s.put(key, hash, value, false);
}
```

调用下面的put方法，put会将新的值放入链表头

```
 1 final V put(K key, int hash, V value, boolean onlyIfAbsent) {
 2     // 在往该 segment 写入前，需要先获取该 segment 的独占锁
 3     //    先看主流程，后面还会具体介绍这部分内容
 4     HashEntry<K,V> node = tryLock() ? null :
 5         scanAndLockForPut(key, hash, value);
 6     V oldValue;
 7     try {
 8         // 这个是 segment 内部的数组
 9         HashEntry<K,V>[] tab = table;
10         // 再利用 hash 值，求应该放置的数组下标
11         int index = (tab.length - 1) & hash;
12         // first 是数组该位置处的链表的表头
13         HashEntry<K,V> first = entryAt(tab, index);
14  
15         // 下面这串 for 循环虽然很长，不过也很好理解，想想该位置没有任何元素和已经存在一个链表这两种情况
16         for (HashEntry<K,V> e = first;;) {
17             if (e != null) {
18                 K k;
19                 if ((k = e.key) == key ||
20                     (e.hash == hash && key.equals(k))) {
21                     oldValue = e.value;
22                     if (!onlyIfAbsent) {
23                         // 覆盖旧值
24                         e.value = value;
25                         ++modCount;
26                     }
27                     break;
28                 }
29                 // 继续顺着链表走
30                 e = e.next;
31             }
32             else {
33                 // node 到底是不是 null，这个要看获取锁的过程，不过和这里都没有关系。
34                 // 如果不为 null，那就直接将它设置为链表表头；如果是null，初始化并设置为链表表头。
35                 if (node != null)
36                     node.setNext(first);
37                 else
38                     node = new HashEntry<K,V>(hash, key, value, first);
39  
40                 int c = count + 1;
41                 // 如果超过了该 segment 的阈值，这个 segment 需要扩容
42                 if (c > threshold && tab.length < MAXIMUM_CAPACITY)
43                     rehash(node); // 扩容后面也会具体分析
44                 else
45                     // 没有达到阈值，将 node 放到数组 tab 的 index 位置，
46                     // 其实就是将新的节点设置成原链表的表头
47                     setEntryAt(tab, index, node);
48                 ++modCount;
49                 count = c;
50                 oldValue = null;
51                 break;
52             }
53         }
54     } finally {
55         // 解锁
56         unlock();
57     }
58     return oldValue;
59 }
```

然后看一下其中的两个方法ensureSegment，scanAndLockForPut

#### 初始化ensureSegment

```
1 private Segment<K,V> ensureSegment(int k) {
 2     final Segment<K,V>[] ss = this.segments;
 3     long u = (k << SSHIFT) + SBASE; // raw offset
 4     Segment<K,V> seg;
 5     if ((seg = (Segment<K,V>)UNSAFE.getObjectVolatile(ss, u)) == null) {
 6         // 这里看到为什么之前要初始化 segment[0] 了，
 7         // 使用当前 segment[0] 处的数组长度和负载因子来初始化 segment[k]
 8         // 为什么要用“当前”，因为 segment[0] 可能早就扩容过了
 9         Segment<K,V> proto = ss[0];
10         int cap = proto.table.length;
11         float lf = proto.loadFactor;
12         int threshold = (int)(cap * lf);
13  
14         // 初始化 segment[k] 内部的数组
15         HashEntry<K,V>[] tab = (HashEntry<K,V>[])new HashEntry[cap];
16         if ((seg = (Segment<K,V>)UNSAFE.getObjectVolatile(ss, u))
17             == null) { // 再次检查一遍该槽是否被其他线程初始化了。
18  
19             Segment<K,V> s = new Segment<K,V>(lf, threshold, tab);
20             // 使用 while 循环，内部用 CAS，当前线程成功设值或其他线程成功设值后，退出
21             while ((seg = (Segment<K,V>)UNSAFE.getObjectVolatile(ss, u))
22                    == null) {
23                 if (UNSAFE.compareAndSwapObject(ss, u, null, seg = s))
24                     break;
25             }
26         }
27     }
28     return seg;
29 }
```



#### 获取写入锁scanAndLockForPut

```
 1     
 2 private HashEntry<K,V> scanAndLockForPut(K key, int hash, V value) {
 3     HashEntry<K,V> first = entryForHash(this, hash);
 4     HashEntry<K,V> e = first;
 5     HashEntry<K,V> node = null;
 6     int retries = -1; // negative while locating node
 7  
 8     // 循环获取锁 失败则循环  成功则跳出循环
 9     while (!tryLock()) {
10         HashEntry<K,V> f; // to recheck first below
11         if (retries < 0) {
12             if (e == null) {
13                 if (node == null) // speculatively create node
14                     // 进到这里说明数组该位置的链表是空的，没有任何元素
15                     // 当然，进到这里的另一个原因是 tryLock() 失败，所以该槽存在并发，不一定是该位置
16                     node = new HashEntry<K,V>(hash, key, value, null);
17                 retries = 0;
18             }
19             else if (key.equals(e.key))
20                 retries = 0;
21             else
22                 // 顺着链表往下走
23                 e = e.next;
24         }
25         // 重试次数如果超过 MAX_SCAN_RETRIES（单核1多核64），那么不抢了，进入到阻塞队列等待锁
26         //    lock() 是阻塞方法，直到获取锁后返回
27         else if (++retries > MAX_SCAN_RETRIES) {
28             lock();
29             break;
30         }
31         else if ((retries & 1) == 0 &&
32                  // 这个时候是有大问题了，那就是有新的元素进到了链表，成为了新的表头
33                  //     所以这边的策略是，相当于重新走一遍这个 scanAndLockForPut 方法
34                  (f = entryForHash(this, hash)) != first) {
35             e = first = f; // re-traverse if entry changed
36             retries = -1;
37         }
38     }
39     return node;
40 }
```

获取锁时，并不直接使用lock来获取，因为该方法获取锁失败时会挂起。

如果tryLock获取锁失败，说明锁被其它线程占用，此时通过循环再次以tryLock的方式申请锁。

如果在循环过程中该Key所对应的链表头被修改，则重置retry次数。如果retry次数超过一定值，则使用lock方法申请锁。



#### 扩容rehash

put 的时候，如果判断该值的插入会导致该 segment 的元素个数超过阈值，那么先进行扩容，再插值。扩容后，容量为原来的 2 倍。

#### get方法

get 过程中是没有加锁的,除非读到的值是空的才会加锁重读.ConcurrentHashMap使用如下方法保证可见性，取得最新的Segment：Segment<K,V> s = (Segment<K,V>)UNSAFE.getObjectVolatile(segments, u)get方法里将要使用的共享变量都定义成volatile,能够在线程之间保持可见性，能够被多线程同时读，并且保证不会读到过期的值之所以不会读到过期的值，是根据java内存模型的happen before原则，对volatile字段的写入操作先于读操作

#### size方法

ConcurrentHashMap会在不上锁的前提逐个Segment计算3次size，如果某相邻两次计算，所有Segment的更新次数之和相等，说明这两次计算过程中无更新操作，则这两次计算出的总size相等，可直接作为最终结果返回。如果这三次计算过程中Map有更新，则对所有Segment加锁重新计算Size。

### Java8实现



Java 8为进一步提高并发性，摒弃了分段锁的方案，而是直接使用一个大的数组，基于CAS的ConcurrentHashMap

#### put方法

```
1 public V put(K key, V value) {
 2     return putVal(key, value, false);
 3 }
 4 final V putVal(K key, V value, boolean onlyIfAbsent) {
 5     if (key == null || value == null) throw new NullPointerException();
 6     // 得到 hash 值
 7     int hash = spread(key.hashCode());
 8     // 用于记录相应链表的长度
 9     int binCount = 0;
10     for (Node<K,V>[] tab = table;;) {
11         Node<K,V> f; int n, i, fh;
12         // 如果数组"空"，进行数组初始化
13         if (tab == null || (n = tab.length) == 0)
14             // 初始化数组，后面会详细介绍
15             tab = initTable();
16  
17         // 找该 hash 值对应的数组下标，得到第一个节点 f
18         else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) {
19             // 如果数组该位置为空，
20             //    用一次 CAS 操作将这个新值放入其中即可，这个 put 操作差不多就结束了，可以拉到最后面了
21             //          如果 CAS 失败，那就是有并发操作，进到下一个循环就好了
22             if (casTabAt(tab, i, null,
23                          new Node<K,V>(hash, key, value, null)))
24                 break;                   // no lock when adding to empty bin
25         }
26         // hash 居然可以等于 MOVED，这个需要到后面才能看明白，不过从名字上也能猜到，肯定是因为在扩容
27         else if ((fh = f.hash) == MOVED)
28             // 帮助数据迁移，这个等到看完数据迁移部分的介绍后，再理解这个就很简单了
29             tab = helpTransfer(tab, f);
30  
31         else { // 到这里就是说，f 是该位置的头结点，而且不为空
32  
33             V oldVal = null;
34             // 获取数组该位置的头结点的监视器锁
35             synchronized (f) {
36                 if (tabAt(tab, i) == f) {
37                     if (fh >= 0) { // 头结点的 hash 值大于 0，说明是链表
38                         // 用于累加，记录链表的长度
39                         binCount = 1;
40                         // 遍历链表
41                         for (Node<K,V> e = f;; ++binCount) {
42                             K ek;
43                             // 如果发现了"相等"的 key，判断是否要进行值覆盖，然后也就可以 break 了
44                             if (e.hash == hash &&
45                                 ((ek = e.key) == key ||
46                                  (ek != null && key.equals(ek)))) {
47                                 oldVal = e.val;
48                                 if (!onlyIfAbsent)
49                                     e.val = value;
50                                 break;
51                             }
52                             // 到了链表的最末端，将这个新值放到链表的最后面
53                             Node<K,V> pred = e;
54                             if ((e = e.next) == null) {
55                                 pred.next = new Node<K,V>(hash, key,
56                                                           value, null);
57                                 break;
58                             }
59                         }
60                     }
61                     else if (f instanceof TreeBin) { // 红黑树
62                         Node<K,V> p;
63                         binCount = 2;
64                         // 调用红黑树的插值方法插入新节点
65                         if ((p = ((TreeBin<K,V>)f).putTreeVal(hash, key,
66                                                        value)) != null) {
67                             oldVal = p.val;
68                             if (!onlyIfAbsent)
69                                 p.val = value;
70                         }
71                     }
72                 }
73             }
74             // binCount != 0 说明上面在做链表操作
75             if (binCount != 0) {
76                 // 判断是否要将链表转换为红黑树，临界值和 HashMap 一样，也是 8
77                 if (binCount >= TREEIFY_THRESHOLD)
78                     // 这个方法和 HashMap 中稍微有一点点不同，那就是它不是一定会进行红黑树转换，
79                     // 如果当前数组的长度小于 64，那么会选择进行数组扩容，而不是转换为红黑树
80                     //    具体源码我们就不看了，扩容部分后面说
81                     treeifyBin(tab, i);
82                 if (oldVal != null)
83                     return oldVal;
84                 break;
85             }
86         }
87     }
88     // 
89     addCount(1L, binCount);
90     return null;
91 }
```

对于put操作，如果Key对应的数组元素为null，则通过CAS操作将其设置为当前值。

如果Key对应的数组元素（也即链表表头或者树的根元素）不为null，则对该元素使用synchronized关键字申请锁，然后进行操作。

如果该put操作使得当前链表长度超过一定阈值，则将该链表转换为树，从而提高寻址效率。

 

#### get方法

对于读操作，由于数组被volatile关键字修饰，因此不用担心数组的可见性问题。

同时每个元素是一个Node实例（Java 7中每个元素是一个HashEntry），它的Key值和hash值都由final修饰，不可变更，无须关心它们被修改后的可见性问题。而其Value及对下一个元素的引用由volatile修饰，可见性也有保障。

 

#### size方法

put方法和remove方法都会通过addCount方法维护Map的size。size方法通过sumCount获取由addCount方法维护的Map的size。
