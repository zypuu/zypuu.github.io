---
title: 关于Linux buff/cache缓存处理
copyright: true
date: 2020-09-12 15:35:15
tags: Linux
categories: 环境运维
comments: true
description: linux相关基础，linux开发环境下开发使用
---

### buff/cache

buffer/cache 一般用于磁盘或文件的缓存，一些shared memory 也会放在这里，一般情况下大部分都是可以回收的，在一些较新版本的Linux 中，free 命令会有一个available 的列，它表示在计算了可回收的buffer/cache的情况下可用的内存

Linux内存回收机制比较复杂，但一般来说会在内存不足的情况下主动去释放cache，在/proc/meminfo 里可以看到相对详细的数据，包括哪些内存是可以回收的，哪些是不能回收的。如果你通过命令这种方法主动去清理的话，如果内存中有一些没有落盘的数据，会在这个时候去写回。如果这个过程顺利进行，就不会有数据的丢失或损坏，但是下次你要使用这些文件，又需要重新从磁盘读到内存，所以大多数情况下没有正面意义，反而会降低效率。

### buff/cache占用过大，清理

在Linux下经常会遇到buff/cache内存占用过多问题，尤其是使用云主机的时候最严重，由于很多是虚拟内存，因此如果buff/cache占用过大的，free空闲内存就很少，影响使用；

可以使用`free -m`查看
![1](1.png)

通常内存关系是：

普通机器：total=used+free

虚拟机器：total=used+free+buff/cache

``` javascript
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
echo 3 > /proc/sys/vm/drop_caches
```

