---
title: websocket分布式共享解决方案
date: 2019-07-14 17:43:21
tags: websocket
categories: Websocket
comments: true
description: websocket项目
---

### websocket分布式问题
如果在单机情况下，当websocket需要给用户推送消息时，由于用户已经与websocket服务建立连接，消息推送能够成功。
但如果在集群情况下，用户甲向websocket发起连接请求，有多台服务时strong text，只能与一台服务建立连接（以服务A为例），而这些websocket服务都是有可能会给用户甲推送消息，这时候的服务B和C并没有建立连接，所以会有一部分消息推送失败。
因为websocket是长连接，session保持在一个server中，所以在不同server在使用websocket推送消息时就需要获取对应的session进行推送，在分布式系统中就无法获取到所有session。

### 解决方案
这里就需要使用一个中间件，将消息推送到个系统中，这里使用redis作为中间件，使用redis的发布订阅功能 pub/sub。
在原来的系统里，由业务模块的服务处理业务逻辑，发生需要推送给用户的数据的时候，发消息给websocket服务，由websocket服务推送消息给用户。
那么，问题的关键就是确保和用户建立连接的websocket服务就是接收到消息的服务，但是由于建立连接的websockt是由ngnx进行负载均衡分配的，接收消息的服务也是无法确定的，这一点并没有什么太好的办法保证。
因此，我们可以换个思路，只要确保对于业务模块发送的消息，所有的websocket服务都能收到消息，只要做到了这一点，与用户建立连接websocket自然也能接收到消息。而且，这种方式相对单台服务收到消息还有一个在处理多点登陆场景下的优势。对于允许多点登录的系统，同一用户可以在多处进行登录，以为着同一用户与多个服务拥有多个websocket连接，这就要求我们保证多台用户消费同一台业务模块的消息。

#### 代码实现

``` javascript
class RedisListenDelegate(object):
    """ redis 队列监控"""

    def __init__(self, system, connection):
        """
            init
        :param system: 系统名
        :param connection: websockets
        """
        self.connection = connection
        self.system = system
        self.redis = self.get_redis()
        self.redis.connect()
        self.listen()

    def parse_redis_conf(self, redis_conf):
        """
            解析redis的配置
        :param redis_conf: redis配置
        :return: redis配置字典
        """
        return re.match(PATTERN['redis_config'], redis_conf).groupdict()

    def get_redis(self):
        """
            获得redis连接客户端
        :return: redis 客户端
        """
        info = self.parse_redis_conf(REDIS_URL)
        return tornadoredis.Client(host=info['host'], port=int(info['port']))

    def handle_message(self, message):
        """
            所有监听redis通道后的处理,都应该继承本函数,本函数是redis通道收到消息后的回调函数
        :param message: redis监听结果信息
        """
        if message.kind != 'message':  # 不处理redis连接信息
            return
        self.connection.message_delegate.send_message(message.body)  # 发送消息

    @gen.coroutine
    def listen(self):
        """
        监听redis通道,回调消息处理
        """
        yield gen.Task(self.redis.subscribe, SUBSCRIBE_KEY.format(self.system))
        yield self.redis.listen(self.handle_message)
		
# 发送消息，访问websocket，最终将消息发布到redis即可，由上面的连接进行监听		
publish(system, message)
```

#### 原理

每个系统作为一个redis通道进行监听，该系统频道收到消息后，该websocket的server会监听到该消息，通过消息内的用户属性，去从本地服务存储的websocket连接获取该用户的连接，然后对该用户发送消息。分布式情况下，所有的server都会监听到该消息，但是用户建立连接只在其中一个server，这样这个server也就可以监听到这个消息，因为连接存在，所以这个server会对用户发送消息，其他server即使监听到但是没有连接，所以不做处理即可。

#### 优点
1、解决了websocket分布式推送消息的问题。
2、代码解耦，websocket服务建立连接，与推送消息到websocket解耦，互不影响，websocket服务挂掉也可以推送消息到redis，无法推消息到redis系统挂掉，也不会影响websocket服务。