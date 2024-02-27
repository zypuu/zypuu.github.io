---
title: Cors跨域技术应用
date: 2018-04-22 20:21:03
tags: 跨域
categories: web
comments: true
description: web开发中，Django框架，如何实现cors跨域技术
---
## CORS简介
CORS全称是"跨域资源共享"（Cross-origin resource sharing）。

它允许浏览器向跨源服务器，发出Request请求，从而克服了AJAX只能同源使用的限制。

CORS需要浏览器和服务器同时支持。目前，所有浏览器都支持该功能，IE浏览器不能低于IE10。

整个CORS通信过程，都是浏览器自动完成，不需要用户参与。对于开发者来说，CORS通信与同源的AJAX通信没有差别，代码完全一样。浏览器一旦发现AJAX请求跨源，就会自动添加一些附加的头信息，有时还会多出一次附加的请求，但用户不会有感觉。

因此，实现CORS通信的关键是服务器。只要服务器实现了CORS接口，就可以跨源通信。

## 简单请求与非简单请求

### 简单请求

#### 条件

满足以下条件，就属于简单请求：
（1) 请求方法是以下三种方法之一：
HEAD
GET
POST
（2）HTTP的头信息不超出以下几种字段：

Accept
Accept-Language
Content-Language
Last-Event-ID
Content-Type：只限于三个值application/x-www-form-urlencoded、multipart/form-data、text/plain

#### 处理流程
对于简单请求，浏览器直接发出CORS请求。具体来说，就是在头信息之中，增加一个Origin字段。
例：
``` javascript
GET /cors HTTP/1.1
Origin: http://api.bob.com
Host: api.alice.com
Accept-Language: en-US
Connection: keep-alive
User-Agent: Mozilla/5.0...
```
上面的头信息中，Origin字段用来说明，本次请求来自哪个源（协议 + 域名 + 端口）。服务器根据这个值，决定是否同意这次请求。
如果Origin指定的域名在许可范围内，服务器返回的响应，会多出几个头信息字段。

``` javascript
Access-Control-Allow-Origin: http://api.bob.com
# 该字段是必须的。它的值要么是请求时Origin字段的值，要么是一个*，表示接受任意域名的请求。
Access-Control-Allow-Credentials: true
# 该字段可选。它的值是一个布尔值，表示是否允许发送Cookie
#另一方面，开发者必须在AJAX请求中打开withCredentials属性。
Access-Control-Expose-Headers: FooBar
# XMLHttpRequest对象的getResponseHeader()方法只能拿到6个基本字段：Cache-Control、Content-Language、Content-Type、Expires、Last-Modified、Pragma。如果想拿到其他字段，就必须在Access-Control-Expose-Headers里面指定
Content-Type: text/html; charset=utf-8
```

### 非简单请求

#### 条件
非简单请求是那种对服务器有特殊要求的请求，比如请求方法是PUT或DELETE，或者Content-Type字段的类型是application/json。

#### 处理流程

非简单请求的CORS请求，会在正式通信之前，增加一次HTTP查询请求，称为"预检"请求（preflight）。

浏览器先询问服务器，当前网页所在的域名是否在服务器的许可名单之中，以及可以使用哪些HTTP动词和头信息字段。只有得到肯定答复，浏览器才会发出正式的XMLHttpRequest请求，否则就报错。
例：

``` javascript
OPTIONS /cors HTTP/1.1
Origin: http://api.bob.com
Access-Control-Request-Method: PUT
Access-Control-Request-Headers: X-Custom-Header
Host: api.alice.com
Accept-Language: en-US
Connection: keep-alive
User-Agent: Mozilla/5.0..
```

"预检"请求用的请求方法是OPTIONS，表示这个请求是用来询问的。头信息里面，关键字段是Origin，表示请求来自哪个源。

### Django代码实现

#### 安装

``` javascript
pip install django-cors-headers
```

#### 添加应用

``` javascript
INSTALLED_APPS = (
    ...
    'corsheaders',
    ...
)
```

#### 中间层设置

``` javascript
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    ...
]
```

#### 添加白名单

``` javascript
# CORS
CORS_ORIGIN_WHITELIST = (
    '127.0.0.1:8080',
    'localhost:8080',
    'www.meiduo.site:8080',
    'api.meiduo.site:8000'
)
CORS_ALLOW_CREDENTIALS = True  # 允许携带cookie
```
凡是出现在白名单中的域名，都可以访问后端接口
CORS_ALLOW_CREDENTIALS 指明在跨域访问中，后端是否支持对cookie的操作。
