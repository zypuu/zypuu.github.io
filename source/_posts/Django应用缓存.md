---
title: 配置缓存
date: 2018-04-20 16:19:05
tags: 缓存
categories: web
comments: true
description: 对于数据使用频率较高，切不经常更新的可以将数据放到缓存里，减少与mysql数据库的交互次数，Django、Flask配置缓存
---

## Django配置缓存

在Django REST framework中使用缓存，可以通过drf-extensions扩展来实现。使用文档[点这里](http://chibisov.github.io/drf-extensions/docs/#caching)

### 安装

``` javascript
pip install drf-extensions
```

### 使用方法

#### 直接添加装饰器

首先导入工具

``` javascript
from rest_framework_extensions.cache.decorators import cache_response
```
即在视图类里面的方法前添加装饰器

``` javascript
class CityView(views.APIView):
    @cache_response()
    def get(self, request, *args, **kwargs):
        ...
```
cache_response可以添加两个参数

``` javascript
@cache_response(timeout=60*60, cache='default')
```
timeout : 缓存的过期时间
cache='default' ：django的缓存后端，即在settings中的cache配置

如果不写参数，则使用默认值，默认值在配置中添加代码：

``` javascript
# DRF扩展
REST_FRAMEWORK_EXTENSIONS = {
    # 缓存时间
    'DEFAULT_CACHE_RESPONSE_TIMEOUT': 60 * 60,
    # 缓存存储
    'DEFAULT_USE_CACHE': 'default',
}
```

#### 使用扩展类继承

除了直接添加装饰器的方法，也可以使用drf-extensions提供的扩展类

drf-extensions提供了三种扩展类
导入工具：

``` javascript
rest_framework_extensions.cache.mixins
```
三个扩展类都在里面。

 1.ListCacheResponseMixin
 用于缓存列表数据类的视图，配合ListModelMixin扩展类使用
 2. RetrieveCacheResponseMixin
用于缓存返回单一数据的视图，与RetrieveModelMixin扩展类配合使用
 3. CacheResponseMixin
 为视图集同时补充List和Retrieve两种缓存，与ListModelMixin和RetrieveModelMixin一起配合使用。

使用方法直接视图类继承即可。
在settings中添加配置，即可设置过期时间与cache

``` javascript
# DRF扩展
REST_FRAMEWORK_EXTENSIONS = {
    # 缓存时间
    'DEFAULT_CACHE_RESPONSE_TIMEOUT': 60 * 60,
    # 缓存存储
    'DEFAULT_USE_CACHE': 'default',
}
```
