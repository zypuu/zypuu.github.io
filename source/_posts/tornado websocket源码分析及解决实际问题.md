---
title: tornado websocket源码分析及解决实际问题
date: 2019-06-30 16:40:00
tags: websocket
categories: Websocket
comments: true
description: tornado websocket的应用
---

## tornado websocket

tornado版本：4.5.2

``` javascript
from tornado.websocket import WebSocketHandler
```
使用tornado.websocket的websockethandler类

### 源码分析

#### 类继承

``` javascript
class WebSocketHandler(tornado.web.RequestHandler):
```
websocket继承的是tornado.web.RequestHandler这个类

#### 获取建立连接

``` javascript
 @tornado.web.asynchronous
    def get(self, *args, **kwargs):
        self.open_args = args
        self.open_kwargs = kwargs

        # Upgrade header should be present and should be equal to WebSocket
        if self.request.headers.get("Upgrade", "").lower() != 'websocket':
            self.set_status(400)
            log_msg = "Can \"Upgrade\" only to \"WebSocket\"."
            self.finish(log_msg)
            gen_log.debug(log_msg)
            return

        # Connection header should be upgrade.
        # Some proxy servers/load balancers
        # might mess with it.
        headers = self.request.headers
        connection = map(lambda s: s.strip().lower(),
                         headers.get("Connection", "").split(","))
        if 'upgrade' not in connection:
            self.set_status(400)
            log_msg = "\"Connection\" must be \"Upgrade\"."
            self.finish(log_msg)
            gen_log.debug(log_msg)
            return

        # Handle WebSocket Origin naming convention differences
        # The difference between version 8 and 13 is that in 8 the
        # client sends a "Sec-Websocket-Origin" header and in 13 it's
        # simply "Origin".
        if "Origin" in self.request.headers:
            origin = self.request.headers.get("Origin")
        else:
            origin = self.request.headers.get("Sec-Websocket-Origin", None)

        # If there was an origin header, check to make sure it matches
        # according to check_origin. When the origin is None, we assume it
        # did not come from a browser and that it can be passed on.
        if origin is not None and not self.check_origin(origin):
            self.set_status(403)
            log_msg = "Cross origin websockets not allowed"
            self.finish(log_msg)
            gen_log.debug(log_msg)
            return

        self.ws_connection = self.get_websocket_protocol()
        if self.ws_connection:
            self.ws_connection.accept_connection()
        else:
            self.set_status(426, "Upgrade Required")
            self.set_header("Sec-WebSocket-Version", "7, 8, 13")
            self.finish()
```
该方法在建立连接前会检验请求头的信息，是否websocket协议，检查connection连接，是否允许跨域请求，还有浏览器的版本等。调用该方法get_websocket_protocol检查通过，则接受该连接的访问最后accept_connection

#### ping pong机制

``` javascript
@property
    def ping_interval(self):
        """The interval for websocket keep-alive pings.

        Set websocket_ping_interval = 0 to disable pings.
        """
        return self.settings.get('websocket_ping_interval', None)

    @property
    def ping_timeout(self):
        """If no ping is received in this many seconds,
        close the websocket connection (VPNs, etc. can fail to cleanly close ws connections).
        Default is max of 3 pings or 30 seconds.
        """
        return self.settings.get('websocket_ping_timeout', None)
		
def ping(self, data):
        """Send ping frame to the remote end."""
        if self.ws_connection is None:
            raise WebSocketClosedError()
        self.ws_connection.write_ping(data)

    def on_pong(self, data):
        """Invoked when the response to a ping frame is received."""
        pass

    def on_ping(self, data):
        """Invoked when the a ping frame is received."""
        pass

```
设置为0则为禁用，websocket协议本身自带pingpong机制，用于连接健康检查和保持连接打开状态，但是这个ping pong机制是与浏览器之间进行的，而不是与websocket客户端，且大多由服务端发起，js本身并不存在这样的机制，浏览器又存在各种版本问题，项目中最好由客户端发起心跳去检验服务端，因为由一个服务端对应多个客户端，最好由客户端发起，为了解决这个问题，最好加入心跳机制，来检验连接存活问题。

#### 最大消息

``` javascript
 @property
    def max_message_size(self):
        """Maximum allowed message size.

        If the remote peer sends a message larger than this, the connection
        will be closed.

        Default is 10MiB.
        """
        return self.settings.get('websocket_max_message_size', None)
```
从源码看最大消息为10M

#### 发消息

``` javascript
 def write_message(self, message, binary=False):
        """Sends the given message to the client of this Web Socket.

        The message may be either a string or a dict (which will be
        encoded as json).  If the ``binary`` argument is false, the
        message will be sent as utf8; in binary mode any byte string
        is allowed.

        If the connection is already closed, raises `WebSocketClosedError`.

        .. versionchanged:: 3.2
           `WebSocketClosedError` was added (previously a closed connection
           would raise an `AttributeError`)

        .. versionchanged:: 4.3
           Returns a `.Future` which can be used for flow control.
        """
        if self.ws_connection is None:
            raise WebSocketClosedError()
        if isinstance(message, dict):
            message = tornado.escape.json_encode(message)
        return self.ws_connection.write_message(message, binary=binary)
```
会判断该连接是否存在，不存在则抛出关闭异常，判断消息是否dict，如果是dict则进行编码

#### 跨域请求

``` javascript
  def check_origin(self, origin):
        """Override to enable support for allowing alternate origins.

        The ``origin`` argument is the value of the ``Origin`` HTTP
        header, the url responsible for initiating this request.  This
        method is not called for clients that do not send this header;
        such requests are always allowed (because all browsers that
        implement WebSockets support this header, and non-browser
        clients do not have the same cross-site security concerns).

        Should return True to accept the request or False to reject it.
        By default, rejects all requests with an origin on a host other
        than this one.

        This is a security protection against cross site scripting attacks on
        browsers, since WebSockets are allowed to bypass the usual same-origin
        policies and don't use CORS headers.

        .. warning::

           This is an important security measure; don't disable it
           without understanding the security implications. In
           particular, if your authentication is cookie-based, you
           must either restrict the origins allowed by
           ``check_origin()`` or implement your own XSRF-like
           protection for websocket connections. See `these
           <https://www.christian-schneider.net/CrossSiteWebSocketHijacking.html>`_
           `articles
           <https://devcenter.heroku.com/articles/websocket-security>`_
           for more.

        To accept all cross-origin traffic (which was the default prior to
        Tornado 4.0), simply override this method to always return true::

            def check_origin(self, origin):
                return True

        To allow connections from any subdomain of your site, you might
        do something like::

            def check_origin(self, origin):
                parsed_origin = urllib.parse.urlparse(origin)
                return parsed_origin.netloc.endswith(".mydomain.com")

        .. versionadded:: 4.0

        """
        parsed_origin = urlparse(origin)
        origin = parsed_origin.netloc
        origin = origin.lower()

        host = self.request.headers.get("Host")

        # Check to see that origin matches host directly, including ports
        return origin == host
```
重写这个方法 return true则允许跨域请求

#### 建立连接之后

``` javascript

    def open(self, *args, **kwargs):
        """Invoked when a new WebSocket is opened.

        The arguments to `open` are extracted from the `tornado.web.URLSpec`
        regular expression, just like the arguments to
        `tornado.web.RequestHandler.get`.
        """
        pass
```
可重写open方法，在建立连接之后进行业务处理

#### 接收消息

``` javascript
def on_message(self, message):
        """Handle incoming messages on the WebSocket

        This method must be overridden.

        .. versionchanged:: 4.5

           ``on_message`` can be a coroutine.
        """
        raise NotImplementedError
```
由源码看，接收消息的方法必须被重写，不然会抛一个异常

#### 关闭连接

``` javascript
def on_close(self):
        """Invoked when the WebSocket is closed.

        If the connection was closed cleanly and a status code or reason
        phrase was supplied, these values will be available as the attributes
        ``self.close_code`` and ``self.close_reason``.

        .. versionchanged:: 4.0

           Added ``close_code`` and ``close_reason`` attributes.
        """
        pass

    def close(self, code=None, reason=None):
        """Closes this Web Socket.

        Once the close handshake is successful the socket will be closed.

        ``code`` may be a numeric status code, taken from the values
        defined in `RFC 6455 section 7.4.1
        <https://tools.ietf.org/html/rfc6455#section-7.4.1>`_.
        ``reason`` may be a textual message about why the connection is
        closing.  These values are made available to the client, but are
        not otherwise interpreted by the websocket protocol.

        .. versionchanged:: 4.0

           Added the ``code`` and ``reason`` arguments.
        """
        if self.ws_connection:
            self.ws_connection.close(code, reason)
            self.ws_connection = None
```
on_close方法为连接关闭之后，可以根据业务进行特殊处理，
close方法，可由服务端根据业务主动关闭连接，可写code与reason，进行特殊处理，前端的websocket可捕获这个code与reason

#### 发送异常

``` javascript
def send_error(self, *args, **kwargs):
    if self.stream is None:
        super(WebSocketHandler, self).send_error(*args, **kwargs)
    else:
    # If we get an uncaught exception during the handshake,
    # we have no choice but to abruptly close the connection.
    # TODO: for uncaught exceptions after the handshake,
    # we can close the connection more gracefully.
    self.stream.close()
```
send_error发送一个异常，之后会触发关闭连接

### 根据业务处理特殊问题

#### websocket建立连接之前拦截
经过源码分析可知，没有on_open这种方法，在建立连接之前做一些操作，所以在分析完浏览器请求，接收这个链接之后，建立连接之前重写get_websocket_protocol方法，进行业务相关操作，再调用，如果不符合想要接入的连接，则可以在这里拒绝掉

#### 主动关闭连接，主动发送异常关闭连接
根据业务需求，我们可以主动调用close方法来主动关闭此次连接，可以设定自定义状态码，然后由前端捕获到，进行业务相关处理。或者调用send_error方法，发送异常来进行业务特殊处理，主动与客户端断开连接

