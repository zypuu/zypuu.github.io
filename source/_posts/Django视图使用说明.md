---
title: Django视图使用说明
date: 2018-04-25 19:15:15
tags: Django
categories: web
comments: true
description: Django视图类的知识梳理
---
## 两个基类
### APIView

APIView是django rest_framework提供的所有视图的基类，继承自django的view父类。
导入：

``` javascript
rest_framework.views.APIView
```
APIView相对于View封装了drf的request对象，response对象，异常捕获功能以及身份认证，权限检查，流量控制等功能。

提供的属性：
authentication_classes 列表或元祖，身份认证类，可重写。
permissoin_classes 列表或元祖，权限检查类
throttle_classes 列表或元祖，流量控制类

经常以常规类视图的定义方法来实现get，post等请求方式。
所以在业务逻辑的视图选择时，如果功能上不包含对数据库的操作（增删改查），不包含序列化器，则继承APIView，直接定义请求方式方法即可。

### GenericAPIView

继承自APIVIew，增加了对于列表视图和详情视图可能用到的通用支持方法。通常使用时，可搭配一个或多个Mixin扩展类。
导入：

``` javascript
rest_framework.generics.GenericAPIView
```
支持定义的属性：

1.列表视图与详情视图通用：
queryset 列表视图的查询集
serializer_class 视图使用的序列化器
2.列表视图使用：
pagination_class 分页控制类
filter_backends 过滤控制后端
3.详情页视图使用：
lookup_field 查询单一数据库对象时使用的条件字段，默认为'pk'
lookup_url_kwarg 查询单一数据时URL中的参数关键字名称，默认与look_field相同

提供的方法：
列表视图与详情视图通用：
1.get_queryset(self)
返回视图使用的查询集，是列表视图与详情视图获取数据的基础，默认返回queryset属性，可以重写，例：

``` javascript
 def get_queryset(self):
        """
        提供数据集
        """
        if self.action == 'list':
            # 如果是list方法，则反回省的查询结果，返回省的列表即parent为none的
            return Area.objects.filter(parent=None)
        else:
            # 不是list则是retrieve,返回所有
            return Area.objects.all()
```
可以添加判断，根据不同请求返回指定不同的查询集。
2.get_serializer_class(self)

返回序列化器类，默认返回serializer_class，可以重写，例如：

``` javascript
def get_serializer_class(self):
        """
        提供序列化器
        """
        if self.action == 'list':
            # 是list，返回省的序列化器
            return AreaSerializer
        else:
            # 不是list，返回区县的序列化器
            return SubAreaSerializer
```
3.get_serializer(self, args, *kwargs)

返回序列化器对象，被其他视图或扩展类使用，如果我们在视图中想要获取序列化器对象，可以直接调用此方法。

注意，在提供序列化器对象的时候，REST framework会向对象的context属性补充三个数据：request、format、view，这三个数据对象可以在定义序列化器时使用。
详情视图使用：
get_object(self) 返回详情视图所需的模型类数据对象，默认使用lookup_field参数来过滤queryset。 在试图中可以调用该方法获取详情信息的模型类对象。

若详情访问的模型类对象不存在，会返回404。

该方法会默认使用APIView提供的check_object_permissions方法检查当前对象是否有权限被访问。

## 五个扩展类

 1. ListModelMixin
 列表视图扩展类，用于查询数据库多个对象，会对list的数据进行过滤和分页，成功返回200
 2. CreateModelMixin
 创建视图扩展类，用于增加数据库信息，成功返回201
 3. RetrieveModelMixin
 详情视图扩展类，用于单一对象的查询，成功返回200
 4. UpdateModelMixin
 更新视图扩展类，用于修改数据库信息，局部更新（partial_update方法），成功返回200
 5. DestroyModelMixin
 删除视图扩展类，用于删除数据库信息（一般都是逻辑删除），成功返回204


## 可用子类（组合类）

 1） CreateAPIView

提供 post 方法

继承自： GenericAPIView、CreateModelMixin

2）ListAPIView

提供 get 方法

继承自：GenericAPIView、ListModelMixin

3）RetireveAPIView

提供 get 方法

继承自: GenericAPIView、RetrieveModelMixin

4）DestoryAPIView

提供 delete 方法

继承自：GenericAPIView、DestoryModelMixin

5）UpdateAPIView

提供 put 和 patch 方法

继承自：GenericAPIView、UpdateModelMixin

6）RetrieveUpdateAPIView

提供 get、put、patch方法

继承自： GenericAPIView、RetrieveModelMixin、UpdateModelMixin

7）RetrieveUpdateDestoryAPIView

提供 get、put、patch、delete方法

继承自：GenericAPIView、RetrieveModelMixin、UpdateModelMixin、DestoryModelMixin


## 视图集ViewSet
相对于前面的视图类，进一步封装
list() 提供一组数据
retrieve() 提供单个数据
create() 创建数据
update() 保存数据
destory() 删除数据
ViewSet视图集类不再实现get()、post()等方法，而是实现动作 action 如 list() 、create() 等，这些动作与请求方式对应。
如果url中使用as_View方法，要把action与请求方式对应。

``` javascript
 url(r'路由规则', ViewSet.as_view({'get':'list'}),
```

### action属性
可以使用self.action获取当前请求视图的action动作，例如：

``` javascript
def get_serializer_class(self):
    if self.action == 'create':
        return OrderCommitSerializer
    else:
        return OrderDataSerializer
```
可以根据请求动作的不同进行if判断，来指定不同的序列化器与查询集

### 常用视图集父类
1） ViewSet

继承自APIView，作用也与APIView基本类似，提供了身份认证、权限校验、流量管理等。

在ViewSet中，没有提供任何动作action方法，需要我们自己实现action方法。

2）GenericViewSet

继承自GenericAPIView，作用也与GenericAPIVIew类似，提供了get_object、get_queryset等方法便于列表视图与详情信息视图的开发。

3）ModelViewSet

继承自GenericAPIVIew，同时包括了ListModelMixin、RetrieveModelMixin、CreateModelMixin、UpdateModelMixin、DestoryModelMixin。

4）ReadOnlyModelViewSet

继承自GenericAPIVIew，同时包括了ListModelMixin、RetrieveModelMixin。

### 视图定义中附加action动作
添加自定义动作需要使用装饰器

``` javascript
rest_framework.decorators.action
```
该装饰器可以接收两个参数
methods: 该action支持的请求方式，列表传递
detail: 表示是action中要处理的是否是视图资源的对象（即是否通过url路径获取主键）
True 表示使用通过URL获取的主键对应的数据对象
False 表示不使用URL获取主键

### 路由routers
在视图集中，可以使用routers快速实现路由信息的配置。
首先在urls.py中导入routers

``` javascript
from rest_framework import routers
```
然后创建router对象

``` javascript
router = routers.SimpleRouter()
router = routers.DefaultRouter()
```
DefaultRouter与SimpleRouter的区别是，DefaultRouter会多附带一个默认的API根视图，返回一个包含所有列表视图的超链接响应数据。
接下来注册router

``` javascript
router.register(r'路由', 视图集, base_name='路由名称前缀')
```
上述代码会形成的路由如下：

``` javascript
^路由/$    name: 前缀-list
^路由/{pk}/$   name: 前缀-detail
```
然后添加路由数据：

``` javascript
urlpatterns = [
    ...
]
urlpatterns += router.urls
```
如果视图中附加了action动作，则形成的路由：

``` javascript
^路由/方法名/$    name: 前缀-方法名
^路由/{pk}/方法名/$  name: 前缀-方法名
```
