---
title: Java Set源码分析
date: 2023-02-06 15:12:00
tags: 源码
categories: Java
comments: true
description: 关于java的Set HashSet, TreeSet, LinkHashSet
---



Set 注重独一无二的性质,该体系集合用于存储无序(存入和取出的顺序不一定相同)元素，值不能重复。对象的相等性本质是对象 hashCode 值（java 是依据对象的内存地址计算出的此序号）判断的，如果想要让两个不同的对象视为相等的，就必须覆盖 Object 的 hashCode 方法和 equals 方法。



### HashSet (Hash表)

1、HashSet ：无序、不重复、无索引
2、HashSet 底层是采用HashMap存储数据的，在JDK8之前是由数组+链表组成的，在JDK8之后是由数组+链表+红黑树组成的，数组的每个索引位置默认存放的是单向链表，如果链表的长度到达了一个临界值就会转为红黑树
3、在哈希表中，最重要的是哈希值，哈希值就是对象的整数表现形式，HashSet 在存数据的时候，会根据数组长度和哈希值计算出要存入的位置，哈希值是根据hashCode()方法计算出来的int型的整数，hashCode()方法定义在Object类中，所有对象都可以调用，默认使用地址值进行计算，一般情况下，自定义的对象都要重写hashCode()方法，利用对象内部的属性值计算哈希值。

#### 构造方法

```
public HashSet() {
    map = new HashMap<>();
}

// 定义
private transient HashMap<E,Object> map;
```

可以看到底层就是HashMap

#### add方法

PRESENT 主要起到占位作用，是一个空对象，用来代替 HashMap 中的 value

```
public boolean add(E e) {
    return map.put(e, PRESENT)==null;
}

...

private static final Object PRESENT = new Object();
```

##### 调用HashMap底层

然后实际调用到了HashMap的底层

```
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}

// 先调用一个hash方法，这是一个hash算法，并不是计算hash值
// 如果 key 的 hash 值 < 216 - 1，那么得到就是 key 的 hash 值，否则就不是
// 用来后面寻找索引位置
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}

...

final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
    // 定义辅助变量
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    // table 其实就是数组，定义：
    // transient Node<K,V>[] table;
    // 判断数组是否为空，如果为空调用 resize() 方法进行第一次扩容
    // 并将扩容后的数组大小返回给 n
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
		...
}
```

##### 第一次初始化扩容

初始化 HashSet(或者是 HashMap)后，数组是空值(null)，需要进行数组的扩容,后面会详解扩容机制

```

final Node<K,V>[] resize() {
    // 定义辅助变量
    Node<K,V>[] oldTab = table;
    // 旧数组长度 0
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    // 旧临界值
    int oldThr = threshold;
    // 新的数组长度和临界值
    int newCap, newThr = 0;
    // 不满足条件
    if (oldCap > 0) {
        if (oldCap >= MAXIMUM_CAPACITY) {
            threshold = Integer.MAX_VALUE;
            return oldTab;
        }
        else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                 oldCap >= DEFAULT_INITIAL_CAPACITY)
            newThr = oldThr << 1; // double threshold
    }
	  // 不满足条件
    else if (oldThr > 0) // initial capacity was placed in threshold
        newCap = oldThr;
    // 第一次扩容
    else {               // zero initial threshold signifies using defaults
        // 新的数组长度默认为 16
        newCap = DEFAULT_INITIAL_CAPACITY;
        // 新的临界值默认为 12
        newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
    }
    // 不满足条件
    if (newThr == 0) {
        float ft = (float)newCap * loadFactor;
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                  (int)ft : Integer.MAX_VALUE);
    }
    // 改变为新的临界值
    threshold = newThr;
    @SuppressWarnings({"rawtypes","unchecked"})
	  // 定义新的数组
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
    // 改变数组
    table = newTab;
    // 旧数组为空，不满足条件
    if (oldTab != null) {
        ...
    }
    // 返回新的数组
    return newTab;
}
```

##### 索引位置计算

第一次扩容后，继续putVal，会计算索引位置

```
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    // 从这里开始
    // 计算应该存放的数组索引
    // 判断该索引位置是否为空，
    if ((p = tab[i = (n - 1) & hash]) == null)
        // 如果为空，直接将结点加到该索引位置
        tab[i] = newNode(hash, key, value, null);
    // 如果不为空，则该位置有可能是链表或红黑树，目前不会执行这一步
    else {
        // 此处省略一大堆代码
    }
    ++modCount; // 修改次数 +1
    // 判断添加后的节点数是否大于临界值
    if (++size > threshold)
        // 如果大于，再次扩容
        resize();
    // 一个空方法，供继承 HashMap 的类去实现
    afterNodeInsertion(evict);
    return null;
}
```

(n - 1) & hash 是计算索引的算法，计算后可以得到一个 0 ~ n -1 范围的值

这里的 n 也就是数组的长度是始终是 2 的 m 次幂，初始是16.扩容后就是32

那么 n -1 用二进制表示就是 0000 1111(高位省略)，二进制与运算(&)可以用来隐藏和显示某些位。这里的 0000 1111 & hash 就是指显示 hash 值的后 4 位，最终就会得到 0 ~ 15 之间的数，作为数组的索引

##### 重复判断

```
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    if ((p = tab[i = (n - 1) & hash]) == null)
        tab[i] = newNode(hash, key, value, null);
    // 上面讲过注释省略，从这里开始分析
	// 如果当前索引位置不为空(是链表或红黑树)
    else {
        // 定义辅助变量
        Node<K,V> e; K k;
        // 判断当前索引位置的结点的 hash 值是否和新结点的 hash 值相同
        // 并且 key 对象相同或者 key 值相等(equlas)
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            // 将当前索引位置的结点赋值给 e
            e = p;
        // 判断当前索引位置是否是红黑树
        else if (p instanceof TreeNode)
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        // 当前索引位置是链表
        else {
            // 代码省略
        }
        // 用 e 是否为空来判断是否存在重复结点
        if (e != null) { // existing mapping for key
            V oldValue = e.value;
            // 判断是否更新 value
            // 这里 value 始终是一个 object 对象，用来占位，所以不需要更新
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;
            // 一个空方法，供 HashMap 的子类实现
            afterNodeAccess(e);
            // 返回旧的 value
            return oldValue;
        }
    }
    // 下面讲过注释省略
    ++modCount;
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}
```

##### 链表转红黑树

添加元素时，当元素长度到达一定阈值，是如何从链表转为红黑树

```
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    if ((p = tab[i = (n - 1) & hash]) == null)
        tab[i] = newNode(hash, key, value, null);
    else {
        Node<K,V> e; K k;
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            e = p;
        else if (p instanceof TreeNode)
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        // 上面讲过注释省略，从这里开始分析
        else {
            // 遍历链表
            for (int binCount = 0; ; ++binCount) {
                // 判断是否到达链表的末尾
                if ((e = p.next) == null) {
                    // 直接将结点添加到链表的末尾
                    p.next = newNode(hash, key, value, null);
                    // 判断链表的结点数是否到达转为红黑树的临界值(8)
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        // bin 可以理解为链表的结点
                        // 当 binCount 为 7 时，此时的位置是第 8 个结点
                        // 但由于刚刚又加入了一个结点，所以实际链表上已经有 9 个结点了
                        // 所以准确的说应该是超过临界值后会转为红黑树，不是到达
                        // 只不过 binCount 是从 0 开始数的，导致结点数少了一个
                        // 转为红黑树
                        treeifyBin(tab, hash);
                    break;
                }
                // 判断当前结点的 hash 是否和新结点的 hash 相同
                // 并且 key 对象相同或者 key 值相同
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    // 直接退出循环，不做任何添加操作
                    break;
                // 继续下一个结点
                p = e;
            }
        }
        // 下面讲过注释省略
        if (e != null) { // existing mapping for key
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;
            afterNodeAccess(e);
            return oldValue;
        }
    }
    ++modCount;
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}
```

然后进入treeifyBin函数

```

final void treeifyBin(Node<K,V>[] tab, int hash) {
    // 定义辅助变量
    int n, index; Node<K,V> e;
    // 判断数组是否为空，或者数组长度小于一个临界值(64)
    if (tab == null || (n = tab.length) < MIN_TREEIFY_CAPACITY)
        // 进行数组扩容，而不是转成红黑树
        resize();
    else if ((e = tab[index = (n - 1) & hash]) != null) {
    	// 转红黑树的代码省略
    }
```

链表上的结点到达了 8 个，但此时数组长度小于 64，是不会将其转为红黑树的，而是进行一次扩容

所以链表转为红黑树的临界条件是结点超过8个，且数组长度超过64

##### 数组达到临界值扩容机制

1. 数组长度（Capacity）：数组长度表示 HashSet 内部数组的大小。在 Java 8 的 HashSet 实现中，默认的初始数组长度是 16。当 HashSet 中的元素数量超过数组长度时，就可能会发生冲突（碰撞），即多个元素哈希值相同但放置在数组同一个位置上。
2. 临界值（Load Factor）：临界值是一个比例值，用于表示 HashSet 中元素数量和数组长度的比例。在 Java 8 的 HashSet 实现中，默认的临界值是 0.75，即当元素数量达到数组长度的 0.75 倍时，就会触发数组的扩容操作。
3. 扩容之后，将旧数组的链表数据移动到新数组，移动链表时并不是把整个链表直接移动到新数组上，而是一个一个结点的移动。因为随着数组扩容后数组长度的变大，每个结点计算出的索引会和之前的不一样

```

final Node<K,V>[] resize() {
    // 定义辅助变量
    Node<K,V>[] oldTab = table;
    // 旧数组长度 0
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    // 旧临界值
    int oldThr = threshold;
    // 新的数组长度和临界值
    int newCap, newThr = 0;
    // 第 n 此扩容，n > 1
    if (oldCap > 0) {
        // 判断旧数组长度是否大于最大值
        if (oldCap >= MAXIMUM_CAPACITY) {
            threshold = Integer.MAX_VALUE;
            return oldTab;
        }
        // 新数组长度扩大两倍
    	// 并判断新数组长度是否 < 最大值，同时旧数组长度是否 >= 初始长度(16)
        else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                 oldCap >= DEFAULT_INITIAL_CAPACITY)
            // 新数组长度临界值扩大两倍
            newThr = oldThr << 1; // double threshold
    }
	// 判断旧数组长度临界值是否 > 0
    else if (oldThr > 0) // initial capacity was placed in threshold
        // 新数组长度为旧数组长度临界值
        // oldCap 为 0，因为如果 > 0 就走第一个条件了
        newCap = oldThr;
    // 第一次扩容
    else {               // zero initial threshold signifies using defaults
        // 新的数组长度默认为 16
        newCap = DEFAULT_INITIAL_CAPACITY;
        // 新的临界值默认为 12
        newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
    }
    // 判断是否新临界值为 0
    if (newThr == 0) {
        // 将新数组大小的 0.75 倍赋值给 ft
        // 初始化 HashMap 时就指定了 loadFactor 为默认临界因子(0.75f)
        float ft = (float)newCap * loadFactor;
        // 如果新的数组大小 < 最大长度，并且 ft < 最大长度，新的数组长度临界值就为 ft
        // 否则为整数的最大值
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                  (int)ft : Integer.MAX_VALUE);
    }
    // 改变为新的临界值
    threshold = newThr;
    @SuppressWarnings({"rawtypes","unchecked"})
	// 定义新的数组
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
    // 改变数组
    table = newTab;
    // 判断旧数组是否为空
    if (oldTab != null) {
        // 按照新的数组长度创建新的数组
        // 并遍历旧数组，将旧数组上的结点一个一个移动到新数组上
        for (int j = 0; j < oldCap; ++j) {
            Node<K,V> e; // 定义辅助变量
            // 判断当前索引位置是否为空
            if ((e = oldTab[j]) != null) {
                // 设置旧数组该索引处为空
                oldTab[j] = null;
                // 判断是否有下一个结点
                if (e.next == null)
                    // 没有下一个结点就直接将该结点移动到新数组上
                    // 注意：索引是由数组长度和 hash 值共同决定的
                    // 此时计算索引用的是新数组的长度，结果可能会与旧数组的索引不同
                    newTab[e.hash & (newCap - 1)] = e;
                // 判断该索引位置是不是一个红黑树
                else if (e instanceof TreeNode)
                    // 移动树上的结点
                    ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                // 该索引位置是一个链表
                else { // preserve order
                    // 定义 lowHead，lowTail，表示低位链表的头结点和尾节点
                    Node<K,V> loHead = null, loTail = null;
                    // 定义 hightHead，hightTail，表示高位链表的头结点和尾节点
                    // 低位链表和高位链表里的位，表示的是数组索引位
                    // 由于数组长度的增加，新数组的索引位置可能不变，也可能变大
                    // 如果不变，就用低位链表；如果变大，就用高位链表
                    Node<K,V> hiHead = null, hiTail = null;
                    Node<K,V> next; // 定义下一个结点
                    do {
                        // 获取下一个结点
                        next = e.next;
                        // 计算新新数组的索引位是否不变
                        if ((e.hash & oldCap) == 0) {
                            // 判断当前结点是否是头结点
                            // 因为最开始定义 loTail 为 null
                            // 而如果添加了一个结点后，loTail 就会指新的结点，不为 null
                            if (loTail == null)
                                // 将当前结点赋值给头结点
                                loHead = e;
                        	// 当前结点不是头结点
                            else
                                // 将当前结点添加到最后
                                loTail.next = e;
                            // 尾节点指向最后的新结点
                            loTail = e;
                        }
                        // 新数组的索引位变大，使用高位链表
                        else {
                            // 和上面的低位链表一样的操作
                            if (hiTail == null)
                                hiHead = e;
                            else
                                hiTail.next = e;
                            hiTail = e;
                        }
                    // 继续下一个结点
                    } while ((e = next) != null);
                    // 判断低位链表是否为非空链表
                    if (loTail != null) {
                        loTail.next = null;
                        // 移动到新数组上的索引不变
                        newTab[j] = loHead;
                    }
                    // 判断高位链表是否为非空链表
                    if (hiTail != null) {
                        hiTail.next = null;
                        // 移动到新数组上的索引变大，相差一个旧数组的长度
                        newTab[j + oldCap] = hiHead;
                    }
                }
            }
        }
    }
    // 返回新的数组
    return newTab;
}
```



### TreeSet（二叉树）

1. TreeSet()是使用二叉树的原理对新 add()的对象按照指定的顺序排序（升序、降序），每增加一个对象都会进行排序，将对象插入的二叉树指定的位置。

2. Integer 和 String 对象都可以进行默认的 TreeSet 排序，而自定义类的对象是不可以的，自己定义的类必须实现 Comparable 接口，并且覆写相应的 compareTo()函数，才可以正常使用。

3. 在覆写 compare()函数时，要返回相应的值才能使 TreeSet 按照一定的规则来排序

4. 比较此对象与指定对象的顺序。如果该对象小于、等于或大于指定对象，则分别返回负数、零或正整数。

   

#### 构造方法

TreeSet秉承了HashSet的一贯做法，内部通过Map来保存key/value数据，由于Set只保存key，所以内部的Map的value公用了一个定义的Object对象PRESENT。 TreeSet由于维持有序性，所以内部通过TreeMap存储数据。

```
public class TreeSet<E> extends AbstractSet<E> implements NavigableSet<E>, Cloneable, java.io.Serializable
{
    // 用于保存TreeMap的对象，会在构造函数当中赋值TreeMap对象
    private transient NavigableMap<E,Object> m;

    // TreeMap当中所有的value都是保存的PRESENT对象
    private static final Object PRESENT = new Object();
}

 TreeSet(NavigableMap<E,Object> m) {
 			this.m = m;
 }
```

几种构造方式：

通过创建TreeMap对象赋值给TreeSet当中NavigableMap<E,Object> m变量；

通过创建NavigableMap<E,Object> m变量并通过addAll方法方法添加到TreeMap当中。

在TreeSet的addAll()方法通过super.addAll()方法调用AbstractCollection的addAll()方法，在该方法内部最后又调用TreeSet的add()方法添加到TreeMap m当中。

```
public TreeSet() {
        this(new TreeMap<E,Object>());
    }


public TreeSet(Comparator<? super E> comparator) {
        this(new TreeMap<>(comparator));
    }


public TreeSet(Collection<? extends E> c) {
        this();
        addAll(c);
    }


public TreeSet(SortedSet<E> s) {
        this(s.comparator());
        addAll(s);
    }
```

add方法

```
public  boolean addAll(Collection<? extends E> c) {
        // Use linear-time version if applicable
        if (m.size()==0 && c.size() > 0 &&
            c instanceof SortedSet &&
            m instanceof TreeMap) {
            SortedSet<? extends E> set = (SortedSet<? extends E>) c;
            TreeMap<E,Object> map = (TreeMap<E, Object>) m;
            Comparator<?> cc = set.comparator();
            Comparator<? super E> mc = map.comparator();
            if (cc==mc || (cc != null && cc.equals(mc))) {
                map.addAllForTreeSet(set, PRESENT);
                return true;
            }
        }
        return super.addAll(c);
    }


public boolean add(E e) {
        return m.put(e, PRESENT)==null;
    }

----------AbstractCollection.java中代码-----------

public boolean addAll(Collection<? extends E> c) {
        boolean modified = false;
        for (E e : c)
            if (add(e))
                modified = true;
        return modified;
    }
```



详情见TreeMap的底层实现方法

### LinkHashSet（HashSet+LinkedHashMap）

 对于 LinkedHashSet 而言，它继承与 HashSet、又基于 LinkedHashMap 来实现的。LinkedHashSet 底层使用 LinkedHashMap 来保存所有元素，它继承与 HashSet，其所有的方法操作上又与 HashSet 相同，因此 LinkedHashSet 的实现上非常简单，调用父类的构造器，底层构造一个 LinkedHashMap 来实现，在相关操作上与父类 HashSet 的操作相同，直接调用父类 HashSet 的方法即可。

```
   public LinkedHashSet(int initialCapacity, float loadFactor) {
       super(initialCapacity, loadFactor, true);
   }
   public LinkedHashSet(int initialCapacity) {
       super(initialCapacity, .75f, true);
   }
   public LinkedHashSet() {
       super(16, .75f, true);
   }
   public LinkedHashSet(Collection<? extends E> c) {
       super(Math.max(2*c.size(), 11), .75f, true);
       addAll(c);
   }
   public LinkedHashSet(int initialCapacity, float loadFactor) {
       super(initialCapacity, loadFactor, true);
   }
   public LinkedHashSet(int initialCapacity) {
       super(initialCapacity, .75f, true);
   }

   public LinkedHashSet() {
       super(16, .75f, true);
   }

   public LinkedHashSet(Collection<? extends E> c) {
       super(Math.max(2*c.size(), 11), .75f, true);
       addAll(c);
   }
   
   ...
   
   
   private transient HashMap<E,Object> map;
    HashSet(int initialCapacity, float loadFactor, boolean dummy) {
        map = new LinkedHashMap<>(initialCapacity, loadFactor);
    }

```

详情见LinkedHashMap的底层实现方法
