---
title: LRU cache
date: 2021-01-27 16:13:00
tags: 算法
categories: 数据算法
comments: true
description: lru cache的实现
---


Lru Cache算法就是LeastRecentlyUsed，意思就是最近最少使用，当缓存满了的时候，不经常使用的就直接删除，挪出空间来缓存新的对象

LRU 缓存机制可以通过哈希表辅以双向链表实现，我们用一个哈希表和一个双向链表维护所有在缓存中的键值对。

双向链表按照被使用的顺序存储了这些键值对，靠近头部的键值对是最近使用的，而靠近尾部的键值对是最久未使用的。

哈希表即为普通的哈希映射（HashMap），通过缓存数据的键映射到其在双向链表中的位置

首先使用哈希表进行定位，找出缓存项在双向链表中的位置，随后将其移动到双向链表的头部，即可在 O(1) 的时间内完成 get 或者 put 操作

本质是一个map集合，然后把map集合里的元素，放到了一个双向链表里，常用的放前面，不常用放后面

golang实现LRU cache

``` javascript
// 结构体
type LRUCache struct {
    size int 		// 大小
    capacity int 	// 容量
    cache map[int]*DLinkedNode 	//	hashmap，双向链表，根据key值查找node
    head, tail *DLinkedNode 	// 头指针， 尾指针
}
// 双向链表
type DLinkedNode struct {
    key, value int // key值，value值
    prev, next *DLinkedNode // 先前指针，后序指针
}
// 初始化链表
func initDLinkedNode(key, value int) *DLinkedNode {
    return &DLinkedNode{
        key: key,
        value: value,
    }
}
// 初始化一个lru cache
func Constructor(capacity int) LRUCache {
	// 初始化结构体
    l := LRUCache{
        cache: map[int]*DLinkedNode{},
        head: initDLinkedNode(0, 0),
        tail: initDLinkedNode(0, 0),
        capacity: capacity,
    }
    // 头指针指向尾指针
    l.head.next = l.tail
    // 尾指针指向头指针
    l.tail.prev = l.head
    return l
}

func (this *LRUCache) Get(key int) int {
    if _, ok := this.cache[key]; !ok {
        return -1
    }
    // 根据key取出值
    node := this.cache[key]
    // 放入头部
    this.moveToHead(node)
    // 返回值
    return node.value
}

// 放入元素
func (this *LRUCache) Put(key int, value int)  {
	// 如果key不是在cache里
    if _, ok := this.cache[key]; !ok {
    	// 创建一个新的节点
        node := initDLinkedNode(key, value)
        // 将新的节点放到head
        this.cache[key] = node
        this.addToHead(node)
        // 大小加1
        this.size++
        // 如果数量大于容量
        if this.size > this.capacity {
        	// 删除尾指针的node'
            removed := this.removeTail()
            // 删除字典中的key数据
            delete(this.cache, removed.key)
            this.size--
        }
    } else {
    	// 如果在字典里，则再次放入的话提高了了频次，移动到头部
        node := this.cache[key]
        node.value = value
        this.moveToHead(node)
    }
}

func (this *LRUCache) addToHead(node *DLinkedNode) {
	// 头部添加，node的前面指向head
    node.prev = this.head
    // node的next指向原先head的next
    node.next = this.head.next
    // head的next的前面指向node
    this.head.next.prev = node
    // head的next指向node
    this.head.next = node
}
// 删除node节点
func (this *LRUCache) removeNode(node *DLinkedNode) {
	// node前面的节点的next指向node的next
    node.prev.next = node.next
    // node的next的前面指向node的前面
    node.next.prev = node.prev
}

func (this *LRUCache) moveToHead(node *DLinkedNode) {
	// 先删除node
    this.removeNode(node)
    // 再把node加入到前面
    this.addToHead(node)
}

func (this *LRUCache) removeTail() *DLinkedNode {
	// 这个时候新的node已经加到前面了，所以要删除的是tail前面的prev
    node := this.tail.prev
    // 删除
    this.removeNode(node)
    return node
}
```