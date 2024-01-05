---
title: tornado-redis版本兼容问题
date: 2020-01-16 19:11:47
tags: Python
categories: Python
comments: true
description: tornado框架，redis
---

#### 问题

主要兼容 tornado5.1 因为这个版本删掉了io_loop所以会造成引用时候报错找不到 io_loop.

#### 解决方法

@tornado.web.asynchronous
@tornado.gen.engine
修改为：

@tornado.gen.coroutine

 

\Python27\Lib\site-packages\tornadoredis\connection.py

大约75行吧，因为bug多自己修改了一下具体还是搜索下面代码为准：

``` javascript
self._stream = IOStream(sock, io_loop=self._io_loop)
修改为：
self._stream = IOStream(sock)
```

