---
title: websocket 心跳机制处理
date: 2019-07-01 13:10:50
tags: websocket
categories: Websocket
comments: true
description: websocket协议
---

### websocket使用问题
在使用websocket的过程中，有时候会遇到网络断开的情况，或者断电，电脑死机，但是在这些情况下服务器端与客户端并没有触发onclose的事件。这样会有：服务器会继续向客户端发送多余的链接，并且这些数据还会丢失。所以就需要一种机制来检测客户端和服务端是否处于正常的链接状态。因此就有了websocket的心跳了。还有心跳，说明还活着，没有心跳说明已经挂掉了。

### 心跳机制
心跳机制是每隔一段时间会向服务器发送一个数据包，告诉服务器自己还活着，同时客户端会确认服务器端是否还活着，如果还活着的话，就会回传一个数据包给客户端来确定服务器端也还活着，否则的话，有可能是网络断开连接了。需要重连

#### 关于需要收到服务端回消息才能确认连接存活 的问题
因为在网络波动，断网，断电情况下，不会触发onclose事件，所以这个时候客户端单独的发消息是可以发送的，这种情况并不能确定断开连接，所以需要服务端回信，如果客户端收到服务端的回信，才能确保连接存活

### 代码实现及原理

#### 心跳代码
前端
``` javascript
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
```
后端

``` javascript
if message == 'heart_beat':
    self.write_message('ok')
```

#### 心跳原理
设立两个定时器，由前端发起，第一个定时器为发送心跳的定时器，隔多少秒之后发送一个心跳信息（一分钟），在发送信息之后出发第二个定时器，5秒之后主动关闭连接，也就是说，需要服务端收到心跳之后5秒之内回复消息，如果5秒之内收到消息，则认为客户端与服务端的连接存活，在收到消息的时候会重置心跳定时器，继续以设定的时间延时后发送心跳，如此循环，实现websocket的心跳机制。

#### 重连机制代码

``` javascript
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
```

#### 重连原理
在onerror与onclose里都加上了重连机制，也就是说websocket遇到异常，或者关闭进行重连，由于websocket本身在触发onerror事件后一定会触发onclose，所以会进行两次重连，为了避免这种情况，加上了一个重连锁的机制，避免重复连接。
当然也不能无限重连，所以要设定重连最大次数，如果到达最大次数还未重连成功，需要用户从新登陆或者刷新浏览器进行重连。
设定重连定时器，一但触发重连，5秒之后初始化websocket，从新建立连接，连接次数加一，释放重连锁。

