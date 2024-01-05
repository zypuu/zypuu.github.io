---
title: 关于session与JWT的认证机制
date: 2018-03-21 14:45:42
tags: web,状态保持
categories: web开发
comments: true
description: http状态保持，cookies的作用，session与jwt的认证机制
---

## 什么是状态保持
说到状态保持，首先要讲一下什么是无状态，http 就是一种无状态协议，浏览器请求服务器是无状态的。

### 无状态
指用户请求过一次后，浏览器与服务器无法知道这个用户做过什么，下一次请求还是新的请求。
<br>
发生无状态的原因：浏览器与服务器之间是使用socket套接字通讯的，在一次访问结束后，服务器将访问结果返回给浏览器之后，会关闭当前的socket连接，浏览器在关闭后，服务器也会销毁当前的页面对象。

### 无状态协议

1.协议对于事务处理没有记忆能力。
2.对同一个 url 请求没有上下文关系。
3.每次的请求都是独立的，它的执行情况和结果与前面的请求和之后的4请求是无直接关系的，它不会受前面的请求应答情况直接影响，也不会直接影响后面的请求应答情况。
4.服务器中没有保存客户端的状态，客户端必须每次带上自己的状态去请求服务器。

### 有状态
与无状态相反，相当于有记忆能力，可以记录之前用户的操作，即状态保持，那怎么实现状态保持呢？

## Cookie

### Cookie的定义
指某些网站为了辨别用户身份、进行会话跟踪而储存在用户本地的数据。（通常经过加密）
<br>
cookie由服务器端生成，发送给客户端浏览器，浏览器可以将cookie的key/value进行保存，下次请求同一网站时就会将cookie同请求信息发送给服务器。
<br>
通过cookie就实现了状态保持，即用户登陆过的信息，访问过的页面数据，都会被放在cookie里进行记录，保存在浏览器，下次请求这个网站时会发送给服务器，服务器就能从cookie中快速获取信息，即知道了用户已经登陆过，访问了哪些数据，保持了用户的登录状态，将相关数据快速呈现。

### 使用cookie的注意事项

 1. cookie是基于域名安全的，不同域名的cookie是不能互相访问的，即同源策略。（在这个页面里可以嵌入窗口iframe，来访问其他域名的cookie）
 2. Cookie是存储在浏览器中的一段纯文本信息，建议不要存储敏感信息如密码，因为电脑上的浏览器可能被其它人使用。
 3. 因为cookie被放在请求报文里发送给服务器，所以服务器端可以通过request对象来获取cookie信息，进行操作。

### 设置cookie与获取cookie

#### 设置cookie
获取response对象

``` javascript
response.set_cookie(‘键’，‘值’，max_age=3600）
```
max_age为过期时间，即第一次访问产生cookie之后，3600秒会自动删除。

#### 获取cookie
请求对象request

``` javascript
request.cookies.get('键')
```
根据之前设置的键就能获取到cookie的值。
## Session
cookie说到建议不要保存用户的敏感信息，很容易会被破解，那么这些敏感信息怎么解决，比如用户登录的用户名，密码，这就要用到session来认证用户。

### 理解session的机制
对于敏感的信息，要保存在服务器中，不能存储在浏览器中，而服务器采用的状态保持的方案就是session认证。<br>
当程序需要为某个客户端的请求创建一个session的时候，服务器首先检查这个客户端的请求里是否已包含了一个session标识 - 称为session id，如果已包含一个session id则说明以前已经为此客户端创建过session，服务器就按照session id把这个session检索出来使用（如果检索不到，可能会新建一个），如果客户端请求不包含session id，则为此客户端创建一个session并且生成一个与此session相关联的session id，session id的值应该是一个既不会重复，又不容易被找到规律以仿造的字符串，这个session id将被在本次响应中返回给客户端保存。

### session依赖于cookie
客户端在访问后，由服务端生成session，根据每一个session都会生成它的唯一标识（uuid），然后以session为键，这个唯一标识为值，存放在cookie里。同时服务端本地也会存session（非关系型数据库存储，如redis），以uuid为键，session的键值对为值，存进服务端本地，访问时，根据这个唯一标识在本地进行读取操作。

#### url重写技术

由于cookie可以被人为的禁止，必须有其他机制以便在cookie被禁止时仍然能够把session id传递回服务器。经常被使用的一种技术叫做URL重写，就是把session id直接附加在URL路径的后面，附加方式也有两种，一种是作为URL路径的附加信息，表现形式为`http://...../xxx;jsessionid=ByOK3vjFD75aPnrF7C2HmdnV6QZcEbzWoWiBYEnLerjQ99zWpBng!-145788764 `
另一种是作为查询字符串附加在URL后面，表现形式为`http://...../xxx?jsessionid=ByOK3vjFD75aPnrF7C2HmdnV6QZcEbzWoWiBYEnLerjQ99zWpBng!-145788764 `
这两种方式对于用户来说是没有区别的，只是服务器在解析的时候处理的方式不同，采用第一种方式也有利于把session id的信息和正常程序参数区分开来。 
为了在整个交互过程中始终保持状态，就必须在每个客户端可能请求的路径后面都包含这个session id。

#### 表单隐藏字段技术

另一种技术叫做表单隐藏字段。就是服务器会自动修改表单，添加一个隐藏字段，以便在表单提交时能够把session id传递回服务器。比如下面的表单： 
   
    <form name="testform" action="/xxx"> 
    <input type="text"> 
    </form> 

    在被传递给客户端之前将被改写成： 

    <form name="testform" action="/xxx"> 
    <input type="hidden" name="jsessionid" value="ByOK3vjFD75aPnrF7C2HmdnV6QZcEbzWoWiBYEnLerjQ99zWpBng!-145788764"> 
    <input type="text"> 
    </form> 
这种技术使用相对较少了。





### session数据的读写

#### 读取session数据

``` javascript
session.get('键')
```

#### 写入session数据

``` javascript
session['键'] = '值'
```

## JWT

### session认证所显露的问题

1.用户通过session认证，都要在服务器端做一次记录，而session是保存在服务器端的内存中，随着用户的增多，服务器端的开销会明显增大。
2.而且用户下次请求还必须要请求在这台服务器上,这样才能拿到授权的资源，这样在分布式的应用上，相应的限制了负载均衡器的能力。这也意味着限制了应用的扩展能力。
3.session是依赖于cookie，如果cookie被截获，很容易受到跨站请求伪造的攻击（csrf），安全性不足。
<br>
这就引入了jwt认证机制

### 什么是JWT
JWT，全名Json Web Token，是一种基于token的认证机制，类似于http协议也是无状态的，它不需要在服务端去保留用户的认证信息或者会话信息。这就意味着基于token认证机制的应用不需要去考虑用户在哪一台服务器登录了，这就为应用的扩展提供了便利。<br>
流程上是这样的：

 - 用户使用用户名密码来请求服务器 
 - 服务器进行验证用户的信息 
 - 服务器通过验证发送给用户一个token
 - 客户端存储token，并在每次请求时附送上这个token值 
 - 服务端验证token值，并返回数据

### JWT的构成
例：
``` javascript
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ
```
如上所示，是一个JWT的token，分为三个部分

#### header头部
第一部分header存两部分信息
``` javascript
{
  'typ': 'JWT',  # 声明类型为jwt
  'alg': 'HS256' # 加密算法 HMAC SHA256
}
```
通过base64算法加密构成第一部分，`eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`

#### payload载荷

载荷是存放有效信息的地方，有效信息分为三部分：

 1. 标准中注册的声明：
 iss: jwt签发者
sub: jwt所面向的用户
aud: 接收jwt的一方
exp: jwt的过期时间，这个过期时间必须要大于签发时间
nbf: 定义在什么时间之前，该jwt都是不可用的.
iat: jwt的签发时间
jti: jwt的唯一身份标识，主要用来作为一次性token,从而回避重放攻击。
 2. 公共的声明：
 添加用户信息，不建议添加敏感信息，因为base64算法是对称算法，可解密
 3. 私有的声明：
 私有声明是提供者和消费者所共同定义的声明。
 定义一个payload
 

``` javascript
{
	"sub": "1234567890",
 	 "name": "John Doe",
 	 "admin": true
}
```
base64算法加密后就是第二段`eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9`

#### signature

jwt的第三部分是一个签证信息，签证信息由三部分组成：
header
payload
secret
这部分信息将header、payload中的base64加密后的信息连接成字符串，然后通过header里声明的HS256算法加上secret进行加密，就构成了jwt的第三部分。

``` javascript
var encodedString = base64UrlEncode(header) + '.' + base64UrlEncode(payload);

var signature = HMACSHA256(encodedString, 'secret'); 
```
构成第三部分`TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ`
三部分构成完整的JWT的token

PS：secret是保存在服务端的，jwt签发也是在服务端，所以secret是服务端的私钥，不能泄露出去。虽然header和payload可以通过base64解密，但是没有secret是无法进行认证的，这就保证了安全性。

### JWT的应用
Django rest framework中应用jwt
详情可参考文档网站：[JWT官方文档](http://getblimp.github.io/django-rest-framework-jwt/)

#### 安装jwt应用

``` javascript
pip install djangorestframework-jwt
```

#### 配置设置
指定jwt认证
``` javascript
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_jwt.authentication.JSONWebTokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ),
}

JWT_AUTH = {
    'JWT_EXPIRATION_DELTA': datetime.timedelta(days=1),
}
```
JWT_EXPIRATION_DELTA指明jwt的有效期

#### 使用jwt返回token
生成口令并返回
``` javascript
from rest_framework_jwt.settings import api_settings

jwt_payload_handler = api_settings.JWT_PAYLOAD_HANDLER
jwt_encode_handler = api_settings.JWT_ENCODE_HANDLER

payload = jwt_payload_handler(user)
token = jwt_encode_handler(payload)
```
比如注册中使用token，因为token要返回输出，所以在定义序列化器时要添加token字段

``` javascript
token = serializers.CharField(label='登录状态token', read_only=True)  # 增加token字段
```

#### 登录功能中使用JWT返回指定字段
将上面的jwt应用于登录认证时，登录成功后，发现api接口只返回了jwt的token，如图所示

![1](1.jpg)
如果想将用户的其他字段比如用户名，怎么返回呢
jwt配合django的内部框架提供了登录验证功能，在Django框架中直接使用jwt的登录验证视图函数obtain_jwt_token

``` javascript
from rest_framework_jwt.views import obtain_jwt_token # 导入包
url(r'^路由规则$', obtain_jwt_token), # url中配置地址
```
定义以上路由地址即可，jwt自带的登录验证便可应用
jwt提供的视图obtain_jwt_token内部逻辑：
	1.定义视图类，继承自APIView
	2.定义序列化器，继承自Serializer，然后调用django内部贡献的authenticate()方法
	3.接收用户名、密码
	4.查询数据库，进行密码对比
	5.如果成功，则生成口令并返回
这是查看obtain_jwt_token的源码，和jwt的官方文档，就可以理解这个视图的工作原理。

然后自定义接口响应值：
1.在users应用下新建utils.py。
2.创建函数

``` javascript
def jwt_response_payload_handler(token, user=None, request=None):
		return {
			'token': token,
			'username':user.username
		}
```
3.在settings.py中配置添加
	'JWT_RESPONSE_PAYLOAD_HANDLER':'users.utils.jwt_response_payload_handler',

然后重新运行即可，效果如下

![2](2.jpg)

### jwt的优点
1.因为json的通用性，所以JWT是可以进行跨语言支持的，像JAVA,JavaScript,NodeJS,PHP等很多语言都可以使用。
2.因为有了payload部分，所以JWT可以在自身存储一些其他业务逻辑所必要的非敏感信息。
3.便于传输，jwt的构成非常简单，字节占用很小，所以它是非常便于传输的。
4.它不需要在服务端保存会话信息, 所以它易于应用的扩展

 