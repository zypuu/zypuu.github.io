---
title: 关于Celery的异步服务使用
date: 2018-05-26 09:49:10
tags: Celery
categories: web
comments: true
description: 在web开发中使用Celery异步服务优化需要等待时长的耗时任务
---

### 什么是Celery？
Celery是一个专注于实时处理和任务调度的分布式任务队列。所谓任务就是消息，消息中的有效载荷中包含要执行任务需要的全部数据。

### 为什么使用Celery

在开发应用中，我们难免会遇到耗时操作，或者需要添加一些定时任务，而服务器本身的框架对于多进程、线程等已经写好，这些附加工作就会被耗时处理，而使用Celery则可以很好的处理这些任务，相当于开了一个额外的进程来处理这些耗时任务，增强了执行效率。

### 应用场景
1. Web应用。当用户触发的一个操作需要较长时间才能执行完成时，可以把它作为任务交给Celery去异步执行，执行完再返回给用户。这段时间用户不需要等待，提高了用户体验与程序执行效率。


2. 定时任务。生产环境经常会跑一些定时任务。假如你有上千台的服务器、上千种任务，定时任务的管理很困难，Celery可以帮助我们快速在不同的机器设定不同种任务。


3. 同步完成的附加工作都可以异步完成。比如发送短信/邮件、推送消息、清理/设置缓存等。

### Celery架构


![1](1.jpg)
Celery Beat：任务调度器，Beat进程会读取配置文件的内容，周期性地将配置中到期需要执行的任务发送给任务队列。
Result Backend：任务处理完后保存状态信息和结果，以供查询。Celery默认已支持Redis、RabbitMQ、MongoDB、Django ORM、SQLAlchemy等方式，当然Redis应该是最佳选择。

### 例：对于django框架web开发中发送短信功能使用Celery优化

#### 为什么要进行优化
因为发送短信是一个等待操作，用户那边也会设置一个60秒等待操作，为了提高用户体验，增强效率，采用Celery进行优化，设置异步任务，处理短信发送功能。

1.在mamange.py同目录下，新建工具包celery_tasks
2.创建config.py
	设置代理人，指定队列，这里连接redis第14个数据库
	

``` javascript
broker_url='redis://‘设置的ip地址’/14'
```

3.创建main.py，创建Celery的对象

``` javascript
from celery import Celery
from . import config
import os
#设置django的配置
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "项目的settings")
# 创建对象
app = Celery('任意字符串')

# 加载配置
app.config_from_object(config)

# 初始化任务
# 在指定的包中找tasks.py文件，在这个文件中找@app.task的函数
app.autodiscover_tasks([
    'celery_tasks.sms',
])

```

4.新建sms工具包，在包中新建tasks.py文件，定义发送短信的函任务

``` javascript
from utils.ytx_sdk.sendSMS import CCP
from celery_tasks.main import app
# 发送短信任务
@app.task(name='sms_send')
def sms_send(mobile, sms_code, expires, template_id):
    CCP.sendTemplateSMS(mobile, sms_code, expires, template_id)
```

5.启动celery的工人
	celery -A celery_tasks.main worker -l info
	
6.调用：sms_send.delay(参数)



