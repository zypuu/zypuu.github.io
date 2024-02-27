---
title: websocket 服务项目搭建
date: 2019-07-10 14:20:37
tags: websocket
categories: web
comments: true
description: websocket项目
---

### 项目背景

根据项目要求，在各系统之间实现异步通知服务，从客户端到服务端，从服务端到客户端实现双向通知。以客户端主动，由客户端向服务端发起http请求，来实现任务的发起，服务端执行异步任务，由于非同步，所以客户端并不知道这个任务什么时候执行完毕，所以需要服务端在执行完任务的时候，主动向客户端发送一个请求，来告知客户端我已经完成任务了，来完成服务端客户端的双向通信。

### websocket选择

一般来说，客户端与服务端的交互都是主动的，客户端与服务端对应的模式就是：客户端请求-服务端响应。而服务端主动向客户端推送消息，客户端不像服务端只有一个地址，要解决这一个问题，我考虑到以下两种方式。

#### Ajax轮询
所谓的Ajax轮询，其实就是定时的通过Ajax查询服务端，客户端按规定时间定时像服务端发送ajax请求，服务器接到请求后马上返回响应信息并关闭连接。

这种技术方式实现起来非常简单，但是这种方式会有非常严重的问题，就是需要不断的向服务器发送消息询问，这种方式会对服务器造成极大的性能浪费。不是实时通信，不顾及应用的状态改变而盲目检查更新，导致服务器资源的浪费，且会加重网络负载，拖累服务器。

#### websocket服务
 WebSocket是HTML5开始提供的一种在单个 TCP 连接上进行全双工通讯的协议。在WebSocket API中，浏览器和服务器只需要做一个握手的动作，然后，浏览器和服务器之间就形成了一条快速通道。两者之间就直接可以数据互相传送。详情看

 这里选择使用websocket


### 开发环境
Python + tornado + vue + websocket

### 前端（客户端）建立websocket
由客户端主动与服务端建立websocket连接，并保持连接通道，通道保持就可以实现双向通信，发消息，建立连接时，根据用户行为（登录等）初始化链接。代码如下

``` javascript
<template>
  <div>
  </div>
</template>
 
<script>
export default {
  name : 'websocket',
  data(){     
    return { 
      websock: null,
      reconnectTime: 0,       // 重连次数
      reconnectData:null,     // 重连定时
      lockReconnect:false,    //避免重复连接，因为onerror之后会立即触发 onclose
      timeout:1000,          //60s一次心跳检测
      timeoutObj:null,        // 客户端发送定时
      serverTimeoutObj:null,  // 收到服务器响应定时
    }
  },
  created(){
    this.initWebSocket()
  },
  destroyed(){
    this.lockReconnect = true
    this.websock.close()                  //离开路由之后断开websocket连接
    clearTimeout(this.reconnectData)      //离开清除 timeout
    clearTimeout(this.timeoutObj)         //离开清除 timeout
    clearTimeout(this.serverTimeoutObj)   //离开清除 timeout
  },
  methods: {
    //初始化weosocket
    initWebSocket(){
      const wsuri = ' ' # 链接地址
      this.websock = new WebSocket(wsuri + '?token=' + this.$store.getters.token)  
      this.websock.onmessage = this.websocketOnMessage     
      this.websock.onopen = this.websocketOnOpen    
      this.websock.onerror = this.websocketOnError    
      this.websock.onclose = this.websocketClose
    },
    //连接建立之后执行send方法发送数据
    websocketOnOpen(){
      this.heartBeat()
      this.reconnectTime = 0
      console.log('websocket服务连接成功') 
    },
    //连接建立失败重连
    websocketOnError(){
      this.reconnect()
    },
    //数据发送
    websocketSend(Data){
      this.websock.send(JSON.stringify(Data))
    },
    //关闭
    websocketClose(e){
      this.reconnect()
    },
    //数据接收
    websocketOnMessage(e){
        this.heartBeat()
    },
    // 心跳检测
    heartBeat(){
      this.timeoutObj && clearTimeout(this.timeoutObj)
      this.serverTimeoutObj && clearTimeout(this.serverTimeoutObj)
      this.timeoutObj = setTimeout(()=>{
        this.websocketSend('heart_beat')
        this.serverTimeoutObj = setTimeout(()=> {
          this.websock.close()     
        }, 5000)
      }, this.timeout)
    },
    // 重连机制
    reconnect(){
      // 避免重复连接
      if(this.lockReconnect){
        return
      }
      this.lockReconnect = true
      console.log('websocket服务异常关闭，正在重连中。。。')
      if (this.reconnectTime >= 5){
        console.log('websocket服务重连失败, 请刷新浏览器')
        return
      }
      this.reconnectData && clearTimeout(this.reconnectData)
      this.reconnectData = setTimeout(()=>{
        this.initWebSocket()
        this.reconnectTime++
        this.lockReconnect = false
      },5000)
    },
  }
}
</script>
```
用户行为操作后，或者前端项目启动后，加载这个组件，然后就会初始化websocket，与服务端进行连接，连接成功之后会触发心跳机制维持连接，可以通过websocket的事件进行收发消息

### 服务端启动websocket服务

#### websocket连接层

前端通过连接地址，指定websocket服务端启动的ip端口，继承websocket基类，创立连接
``` javascript
from base.websocket import BaseWebSocket
from lib.routes import route
from services.connection import Connection


@route(r'/websocket')
class AthenaWebsocket(BaseWebSocket):
    """websocket连接层，创建连接"""
    connection = Connection('athena')
```


#### websocket基类
建立连接成功后，可对该连接进行处理，将该用户访问的连接保存在本地，维护连接通道

``` javascript
from datetime import datetime

import ujson
from tornado.websocket import WebSocketHandler


class BaseWebSocket(WebSocketHandler):
    """ websocket基类"""
	user = None
	connection = None  # 维护的连接

    async def open(self, *args, **kwargs):
        """
            建立websocket时，触发的方法，可对用户进行注册，保存本地连接实例
        """
		  self.connection.register(self)

    def on_message(self, info):
        """处理由web页面传递的消息
        """
        try:
            message = ujson.loads(info)
            # 心跳处理
            if message == 'heart_beat':
                self.write_message('ok')
        except Exception as e:
           pass

    def on_close(self):
        """websocket 关闭， 移除socket连接实例
        """
        if self.user:
            self.connection.unregister(self)

    def check_origin(self, origin):
        """
             默认允许跨域请求
        :param origin:
        """
        return True

```

#### 保存连接
用户通过前端建立连接后，将连接实例保存在本地（无法保存在redis，mysql等库中，为连接对象），之后通过连接实例进行收发消息

``` javascript
class Connection(object):
    """连接状态"""

    def __init__(self, system):
        """
            连接初始化，若需重写连接状态的部分逻辑，替换对应的代理"

        """
		# 保存的websocket连接实例
        self.websockets = defaultdict(list)
        self.message_delegate = MessageDelegate(system, self.websockets)  # 发送消息代理类
        self.redis_delegate = RedisListenDelegate(system, self)  # redis 监听类

    def register(self, item):
        """
            用户建立webscoket
            1. 添加新连接， 
        :param item: websocket instance
        """
        if item in self.websockets[item.user]:
            return
        self.websockets[item.user].append(item)

    def unregister(self, item):
        """
            用户退出websocket
             1. 删除连接,  2.删除用户在线状态
        :param item: websocket instance
        """
        self.websockets[item.user].remove(item)
```

#### 发送消息
服务端只要调用发消息的方法，从本地根据连接的用户属性，获取当前用户在建立连接时保存的连接，然后根据连接对象实现主动向客户端发送消息

``` javascript
class MessageDelegate(object):
    """ 消息代理"""

    def __init__(self, system, websockets):
        """
            init
        :param websockets: websoctets
        """
        self.websockets = websockets  # 和connection宿主维护同一个连接记录池

    def send_message(self, message):
        """
             向指定用户发送请求,若用户在线直接发送
        :param message:
        """
        msg = ujson.loads(message)
        receiver = msg.get('receiver')
        if receiver:
            self.unicast(receiver, msg)

    def unicast(self, receiver, message):
        """
            指定用户发送消息
        :param receiver: 用户
        :param message: 消息
        # :return:
        """
        websockets = self.websockets.get(receiver, [])
        if not websockets:
            return
        for websocket in websockets:
            self.write_message(websocket, message)

    def write_message(self, socket, message):
        """
            向客户端发消息
        :param socket: 需要发送信息的websocketHandler连接
        :param message: 发送的信息
        """
        socket.write_message(message)
```

