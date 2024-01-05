---
title: Python的单例模式
date: 2018-05-28 20:21:03
tags: Python
categories: Python
comments: true
description: Python的设计模式，单例模式简介以及如何实现
---

## 什么是单例模式
顾名思义：就是单个模式

单例模式是一种常见的软件设置模式，在它的核心结构中只包含一个被称为单例类的特殊类，通过单例模式可以保证系统中的一个类只有一个实例而且该实例易于外界访问，从而方便对实例个数的控制并节约系统资源。如果希望在系统中某个对象只能存在一个，单例模式是最好的解决方案。

比如，某个服务器程序的配置信息存放在一个文件中，客户端通过一个 AppConfig 的类来读取配置文件的信息。如果在程序运行期间，有很多地方都需要使用配置文件的内容，也就是说，很多地方都需要创建 AppConfig 对象的实例，这就导致系统中存在多个 AppConfig 的实例对象，而这样会严重浪费内存资源，尤其是在配置文件内容很多的情况下。事实上，类似 AppConfig 这样的类，我们希望在程序运行期间只存在一个实例对象。

单例模式的要点有三类

某个类只能有一个实例
它必须创建这个实例
它必须自行向整个系统提供这个实例

## 实现单例的方法

### 模块

其实，Python 的模块就是天然的单例模式，因为模块在第一次导入时，会生成 .pyc 文件，当第二次导入时，就会直接加载 .pyc 文件，而不会再次执行模块代码。因此，我们只需把相关的函数和数据定义在一个模块中，就可以获得一个单例对象了。

### 使用装饰器

``` javascript
def Singleton(cls):
    _instance = {}

    def _singleton(*args, **kargs):
        if cls not in _instance:
            _instance[cls] = cls(*args, **kargs)
        return _instance[cls]

    return _singleton


@Singleton
class A(object):
    a = 1

    def __init__(self, x=0):
        self.x = x


a1 = A(2)
a2 = A(3)
```

### 使用类

``` javascript
class Singleton(object):

    def __init__(self):
        pass

    @classmethod
    def instance(cls, *args, **kwargs):
        if not hasattr(Singleton, "_instance"):
            Singleton._instance = Singleton(*args, **kwargs)
        return Singleton._instance
```
但是这种情况下，多线程是无法使用的，存在问题

#### 优化

``` javascript
class Singleton(object):

    def __init__(self):
        pass

    @classmethod
    def instance(cls, *args, **kwargs):
        if not hasattr(Singleton, "_instance"):
            Singleton._instance = Singleton(*args, **kwargs)
        return Singleton._instance

import threading

def task(arg):
    obj = Singleton.instance()
    print(obj)

for i in range(10):
    t = threading.Thread(target=task,args=[i,])
    t.start()
```
结果如下

``` javascript
<__main__.Singleton object at 0x02C933D0>
<__main__.Singleton object at 0x02C933D0>
<__main__.Singleton object at 0x02C933D0>
<__main__.Singleton object at 0x02C933D0>
<__main__.Singleton object at 0x02C933D0>
<__main__.Singleton object at 0x02C933D0>
<__main__.Singleton object at 0x02C933D0>
<__main__.Singleton object at 0x02C933D0>
<__main__.Singleton object at 0x02C933D0>
<__main__.Singleton object at 0x02C933D0>
```
看起来也没有问题，那是因为执行速度过快，如果在init方法中有一些IO操作，就会发现问题了，下面我们通过time.sleep模拟

我们在上面__init__方法中加入以下代码：

``` javascript
 def __init__(self):
        import time
        time.sleep(1)
```
结果如下

``` javascript
<__main__.Singleton object at 0x034A3410>
<__main__.Singleton object at 0x034BB990>
<__main__.Singleton object at 0x034BB910>
<__main__.Singleton object at 0x034ADED0>
<__main__.Singleton object at 0x034E6BD0>
<__main__.Singleton object at 0x034E6C10>
<__main__.Singleton object at 0x034E6B90>
<__main__.Singleton object at 0x034BBA30>
<__main__.Singleton object at 0x034F6B90>
<__main__.Singleton object at 0x034E6A90>
```
这时就发现问题，按照以上方式创建的单例，无法支持多线程

解决办法：加锁！未加锁部分并发执行,加锁部分串行执行,速度降低,但是保证了数据安全

``` javascript
import time
import threading
class Singleton(object):
    _instance_lock = threading.Lock()

    def __init__(self):
        time.sleep(1)

    @classmethod
    def instance(cls, *args, **kwargs):
        with Singleton._instance_lock:
            if not hasattr(Singleton, "_instance"):
                Singleton._instance = Singleton(*args, **kwargs)
        return Singleton._instance


def task(arg):
    obj = Singleton.instance()
    print(obj)
for i in range(10):
    t = threading.Thread(target=task,args=[i,])
    t.start()
time.sleep(20)
obj = Singleton.instance()
print(obj)
```
这样就差不多了，但是还是有一点小问题，就是当程序执行时，执行了time.sleep(20)后，下面实例化对象时，此时已经是单例模式了，但我们还是加了锁，这样不太好，再进行一些优化，把intance方法，改成下面的这样就行：

``` javascript
 @classmethod
    def instance(cls, *args, **kwargs):
        if not hasattr(Singleton, "_instance"):
            with Singleton._instance_lock:
                if not hasattr(Singleton, "_instance"):
                    Singleton._instance = Singleton(*args, **kwargs)
        return Singleton._instance
```
这样，一个可以支持多线程的单例模式就完成了
### __new__方法实现单例
我们知道，当我们实例化一个对象时，是先执行了类的__new__方法（我们没写时，默认调用object.__new__），实例化对象；然后再执行类的__init__方法，对这个对象进行初始化，所有我们可以基于这个，实现单例模式。

``` javascript
import threading
class Singleton(object):
    _instance_lock = threading.Lock()

    def __init__(self):
        pass


    def __new__(cls, *args, **kwargs):
        if not hasattr(Singleton, "_instance"):
            with Singleton._instance_lock:
                if not hasattr(Singleton, "_instance"):
                    Singleton._instance = object.__new__(cls)  
        return Singleton._instance

obj1 = Singleton()
obj2 = Singleton()
print(obj1,obj2)

def task(arg):
    obj = Singleton()
    print(obj)

for i in range(10):
    t = threading.Thread(target=task,args=[i,])
    t.start()
```
结果如下

``` javascript
<__main__.Singleton object at 0x038B33D0> <__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
<__main__.Singleton object at 0x038B33D0>
```
采用这种方式的单例模式，以后实例化对象时，和平时实例化对象的方法一样 obj = Singleton() 

### 元类创建单例
1.类由type创建，创建类时，type的__init__方法自动执行，类() 执行type的 __call__方法(类的__new__方法,类的__init__方法)
2.对象由类创建，创建对象时，类的__init__方法自动执行，对象()执行类的 __call__ 方法

``` javascript
import threading

class SingletonType(type):
    _instance_lock = threading.Lock()
    def __call__(cls, *args, **kwargs):
        if not hasattr(cls, "_instance"):
            with SingletonType._instance_lock:
                if not hasattr(cls, "_instance"):
                    cls._instance = super(SingletonType,cls).__call__(*args, **kwargs)
        return cls._instance

class Foo(metaclass=SingletonType):
    def __init__(self,name):
        self.name = name


obj1 = Foo('name')
obj2 = Foo('name')
print(obj1,obj2)
```