---
title: Java List以及扩容分析
date: 2023-02-01 8:42:00
tags: Java
categories: Java
comments: true
description: 关于java的Collection List ArrayList、Vector 和 LinkedList
---



### ArrayList（数组）

ArrayList 是最常用的 List 实现类，内部是通过数组实现的，它允许对元素进行快速随机访问。数组的缺点是每个元素之间不能有间隔，当数组大小不满足时需要增加存储能力，就要将已经有数组的数据复制到新的存储空间中。当从 ArrayList 的中间位置插入或者删除元素时，需要对数组进行复制、移动、代价比较高。因此，它适合随机查找和遍历，不适合插入和删除



#### 三种构造方式

```java
public class ArrayList<E> extends AbstractList<E>
        implements List<E>, RandomAccess, Cloneable, java.io.Serializable {

	//...
	
	//默认初始容量大小
	private static final int DEFAULT_CAPACITY = 10;
	
	private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};
	
	//1.创建时指定容量大小
	public ArrayList(int initialCapacity) {
	    if (initialCapacity > 0) {
	        this.elementData = new Object[initialCapacity];
	    } else if (initialCapacity == 0) {
	        this.elementData = EMPTY_ELEMENTDATA;
	    } else {
	        throw new IllegalArgumentException("Illegal Capacity: "+
	                                           initialCapacity);
	    }
	}
	
	//2.无参构造函数，使用初始容量 10 来构造一个空列表
	public ArrayList() {
	    this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
	}
	
	//3.构造包含指定 collection 元素的列表，这些元素利用该集合的迭代器按顺序返回
	public ArrayList(Collection<? extends E> c) {
	    elementData = c.toArray();
	    if ((size = elementData.length) != 0) {
	        // c.toArray might (incorrectly) not return Object[] (see 6260652)
	        if (elementData.getClass() != Object[].class)
	            elementData = Arrays.copyOf(elementData, size, Object[].class);
	    } else {
	        // replace with empty array.
	        this.elementData = EMPTY_ELEMENTDATA;
	    }
	}

	//...
}
```

以无参数构造方法创建 ArrayList 时，实际上初始化赋值的是一个空数组。当真正对数组进行添加元素操作时，才真正分配容量。即向数组中添加第一个元素时，数组容量扩为 10。

无参构造的 ArrayList 对象时，直接创建了长度是 10 的 Object[] 数组 elementData



#### 扩容过程

在添加元素的时候

```java
//向列表末尾添加元素，添加成功时返回 true
public boolean add(E e) {
	//调用了 ensureCapacityInternal 方法，确保数组下标不越界
	ensureCapacityInternal(size + 1);  // Increments modCount!!
	//添加元素
	elementData[size++] = e;
	return true;
}

...


private void ensureCapacityInternal(int minCapacity) {
    ensureExplicitCapacity(calculateCapacity(elementData, minCapacity));
}
// 当要向列表中添加第 1 个元素时，minCapacity 为 1，在 Math.max()方法比较后，minCapacity 变为 10。
private static int calculateCapacity(Object[] elementData, int minCapacity) {
    if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
    	//返回默认的容量和传入参数的较大值
        return Math.max(DEFAULT_CAPACITY, minCapacity);
    }
    return minCapacity;
}

...

//判断是否需要扩容
private void ensureExplicitCapacity(int minCapacity) {
    modCount++;
    // overflow-conscious code
    if (minCapacity - elementData.length > 0)
    	//调用 grow 方法进行扩容
        grow(minCapacity);
}
```

当添加第 1 个元素时，elementData.length 为 0，因为执行了 ensureCapacityInternal() 方法 ，所以 minCapacity 此时为 10。此时，minCapacity - elementData.length > 0成立，所以会进入 grow(minCapacity) 方法；

当添加第 2 个元素时，minCapacity = 2，此时 elementData.length 在添加第一个元素后扩容成 10 了。此时，minCapacity - elementData.length > 0 不成立，所以不会执行 grow(minCapacity) 方法，既不会进行扩容。添加第 3、4、···直到第 10 个元素时，依然不会执行 grow 方法，数组容量都为 10；

当添加第 11 个元素时，minCapacity = 11，此时 minCapacity - elementData.length = 11 - 10 > 0 成立，因此便进行扩容操作


```java
//要分配的最大数组大小
private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;

//扩容的核心代码
private void grow(int minCapacity) {
    // oldCapacity 为旧容量，newCapacity 为新容量
    int oldCapacity = elementData.length;
    //将 oldCapacity 右移一位，即相当于 oldCapacity / 2，整句运算式的结果就是将新容量更新为旧容量的 1.5 倍
    int newCapacity = oldCapacity + (oldCapacity >> 1);
    //检查新容量 newCapacity 是否大于最小需要容量 minCapacity，若还是小于最小需要容量，那么就把最小需要容量当作数组的新容量
    if (newCapacity - minCapacity < 0)
        newCapacity = minCapacity;
    //如果 minCapacity 大于最大容量，则新容量则为`Integer.MAX_VALUE`，否则，新容量大小则为 MAX_ARRAY_SIZE 即为 Integer.MAX_VALUE - 8。
    if (newCapacity - MAX_ARRAY_SIZE > 0)
        newCapacity = hugeCapacity(minCapacity);
    // minCapacity is usually close to size, so this is a win:
    /*
		(1) Arrays.copyOf()方法返回的数组是新的数组对象，原数组对象仍是原数组对象不变;
		(2) 该拷贝不会影响原来的数组, copyOf()的第二个自变量指定要建立的新数组长度，如果新数组的长度超过原数组的长度，则保留数组默认值;
	*/
    elementData = Arrays.copyOf(elementData, newCapacity);
}

...
// 如果新容量 newCapacity > MAX_ARRAY_SIZE，则执行 hugeCapacity() 方法来比较 minCapacity 和 MAX_ARRAY_SIZE：
// 如果 minCapacity 大于最大容量，则新容量 newCapacity 则为 Integer.MAX_VALUE；
// 否则，新容量 newCapacity 则为 MAX_ARRAY_SIZE 即为 Integer.MAX_VALUE - 8；
private static int hugeCapacity(int minCapacity) {
    if (minCapacity < 0) // overflow
        throw new OutOfMemoryError();
    return (minCapacity > MAX_ARRAY_SIZE) ?
        Integer.MAX_VALUE :
        MAX_ARRAY_SIZE;
}
```

当向 ArrayList 中添加一个新元素时，ArrayList 会先检查当前数组中是否还有剩余的空间可以存储元素；
如果有剩余空间，则将元素添加到数组 elementData 的尾部，然后更新数组 elementData 中的元素数量 size 即可。
如果没有剩余空间，则底层通过 ArrayList 扩容的核心方法 grow(int minCapacity) 来进行扩容，具体步骤如下：
将数组 elementData 的长度设置为旧容量 oldCapacity；
然后取 oldCapacity 的大约 1.5 倍作为新容量 newCapacity，具体的计算方法是 newCapacity = oldCapacity + (oldCapacity << 1)，这里通过使用移位运算符来加快计算速度；
通过 Arrays.copyOf() 方法来创建一个长度为 newCapacity 的数组，并且将旧数组中的元素复制到新数组中，复制完成后，ArrayList 就会开始使用新数组来存储元素，并更新数组的大小和元素数量



### Vector

Vector 与 ArrayList 一样，也是通过数组实现的，不同的是它支持线程的同步，即某一时刻只有一个线程能够写 Vector，避免多线程同时写而引起的不一致性，但实现同步需要很高的花费，因此，访问它比访问 ArrayList 慢。

#### 三种构造方式

```
   public Vector() {
     // 当前是无参构造方法 Vector vector = new Vector();
     // 其实你不给参数，它默认就是10，它会去调用一个有参方法
        this(10);
    }
    
    ...
    
    public Vector(int initialCapacity) {
    	// 这句话好比如 Vector vector = new Vector(5);
    	// 意思代表着如果你没有参数我默认就是10，如何调用有参方法
    	// 如果构造方法有值的话，则直接走当前方法
        this(initialCapacity, 0);
    }
    
    ...
    
    public Vector(int initialCapacity, int capacityIncrement) {
        super();
        // 判断当前的值是否为负数，则会抛出异常
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        /**
        * 第一个值代表当前数组初始化的大小
        * 第二个值代表待会儿我们可以在扩容的那个地方说，它起到了关键
        * 性作用
        */
        this.elementData = new Object[initialCapacity];
        // 如果我们在刚刚开始构建Vector的时候你没有传入参数
        // 或者说你只传了一个参数，在调用当前方法的时候，它是
        // 默认传入0的
        this.capacityIncrement = capacityIncrement;
    }

```



#### 扩容过程

在添加元素的时候

```
// 可以看见该方法synchronized修饰，则是线程安全的
    public synchronized boolean add(E e) {
        modCount++;// 修改次数 加加
        // protected int elementCount; 则记录当前，每次加1
        ensureCapacityHelper(elementCount + 1);
        elementData[elementCount++] = e;
        return true;
    }

...

    private void ensureCapacityHelper(int minCapacity) {
        // overflow-conscious code
        // 如果在无参构造方法在第一次进行添加的时候，
        // 此时的minCapacity 等于1 而elementDta.length等于10
        // 1-10 = -9; -9不大于0 所以说不满足条件
        if (minCapacity - elementData.length > 0)
            grow(minCapacity);
    }
```

经过多次添加的时候，满足条件，会触发扩容

```
    private void grow(int minCapacity) {
        // overflow-conscious code
        // 此时我们的elementData.length是等于10 
        int oldCapacity = elementData.length;
        /**
        * 这边 运用了一个三元运算符就行判断
        * capacityIncrement  就是前面说的起到关键性作用的变量
        * 假设，我们在创建Vector的时候是一个无参的构造器，或者说只有一个
        * 参数，那么此时的capacityIncrement 等于0，前面提到过 默认传给
        * 它的就是0，0不大于0所以结果为 oldCapacity + oldCapacity 
        * 也就是10加上10 等于20，以2倍的速度进行增加
        * 如果你是Vector vector = new Vector(5,5);这样创建
        * 结果明显而知，5肯定大于0的
        */
        int newCapacity = oldCapacity + ((capacityIncrement > 0) ?
                                         capacityIncrement : oldCapacity);
        
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        // private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8 = 2147483639
        // 判断当前是否超出了一个最大值
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        // 调用了Arrays.copyOf方法，
        // 为什么调用Arrays.copyOf，为了就是保留原有的数据
        // 把新的newCapacity赋值给它后再copy给原来的elementData
        // 则当前扩容完成
        elementData = Arrays.copyOf(elementData, newCapacity);
    }
```



### LinkedList

LinkedList 是用链表结构存储数据的，很适合数据的动态插入和删除，随机访问和遍历速度比较慢。另外，他还提供了 List 接口中没有定义的方法，专门用于操作表头和表尾元素，可以当作堆栈、队列和双向队列使用。

可以参考算法 [数组、链表和跳表](https://zypuu.github.io/2021/02/01/%E6%95%B0%E7%BB%84%E3%80%81%E9%93%BE%E8%A1%A8%E5%92%8C%E8%B7%B3%E8%A1%A8/)