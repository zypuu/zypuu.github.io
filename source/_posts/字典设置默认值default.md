---
title: 字典设置默认值 defaultdict
date: 2020-07-20 14:45:00
tags: Python
categories: Python
comments: true
description: python基础
---


### 关于python中defaultdict的用法

当我使用普通的字典时，用法一般是dict={},添加元素的只需要dict[element] =value即，调用的时候也是如此，dict[element] = xxx,但前提是element字典里，如果不在字典里就会报错，keyerror的错误。


为了防止报错，我们可以先给字典中的键设置默认值，再对其进行操作，这里就用到defaultdict

defaultdict可以指定str，list，set，int默认值，
对应的分别是空字符串，[], （），0

``` javascript
dict1 = defaultdict(str) # 列表，集合，数字一样
```
之后即可对dict1操作，不存在的键即取到默认值。
