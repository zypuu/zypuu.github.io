---
title: Elasticsearch的使用
date: 2018-08-01 20:02:55
tags: web,search
categories: web开发
comments: true
description: Elasticsearch的初步介绍，以及简单使用。
---

##  ES
ES=elaticsearch简写， Elasticsearch是一个开源的高扩展的分布式全文检索引擎，它可以近乎实时的存储、检索数据；本身扩展性很好，可以扩展到上百台服务器，处理PB级别的数据。 
Elasticsearch也使用Java开发并使用Lucene作为其核心来实现所有索引和搜索的功能，但是它的目的是通过简单的RESTful API来隐藏Lucene的复杂性，从而让全文搜索变得简单。
## ES工作原理
当ElasticSearch的节点启动后，它会利用多播(multicast)(或者单播，如果用户更改了配置)寻找集群中的其它节点，并与之建立连接。这个过程如下图所示： 
![1](1.jpg)
## ES核心概念

### Cluster：集群
ES可以作为一个独立的单个搜索服务器。不过，为了处理大型数据集，实现容错和高可用性，ES可以运行在许多互相合作的服务器上。这些服务器的集合称为集群。

### Node：节点
形成集群的每个服务器称为节点。

### Shard：分片
当有大量的文档时，由于内存的限制、磁盘处理能力不足、无法足够快的响应客户端的请求等，一个节点可能不够。这种情况下，数据可以分为较小的分片。每个分片放到不同的服务器上。 
当你查询的索引分布在多个分片上时，ES会把查询发送给每个相关的分片，并将结果组合在一起，而应用程序并不知道分片的存在。即：这个过程对用户来说是透明的。

### Replia：副本
为提高查询吞吐量或实现高可用性，可以使用分片副本。 
副本是一个分片的精确复制，每个分片可以有零个或多个副本。ES中可以有许多相同的分片，其中之一被选择更改索引操作，这种特殊的分片称为主分片。 
当主分片丢失时，如：该分片所在的数据不可用时，集群将副本提升为新的主分片。

### 全文检索
全文检索就是对一篇文章进行索引，可以根据关键字搜索，类似于mysql里的like语句。 
全文索引就是把内容根据词的意义进行分词，然后分别创建索引，例如”你们的激情是因为什么事情来的” 可能会被分词成：“你们“，”激情“，“什么事情“，”来“ 等token，这样当你搜索“你们” 或者 “激情” 都会把这句搜出来。
##  ES数据架构的主要概念（与关系数据库Mysql对比）
{% asset_img 2.jpg  %}
（1）关系型数据库中的数据库（DataBase），等价于ES中的索引（Index） 
（2）一个数据库下面有N张表（Table），等价于1个索引Index下面有N多类型（Type）， 
（3）一个数据库表（Table）下的数据由多行（ROW）多列（column，属性）组成，等价于1个Type由多个文档（Document）和多Field组成。 
（4）在一个关系型数据库里面，schema定义了表、每个表的字段，还有表和字段之间的关系。 与之对应的，在ES中：Mapping定义索引下的Type的字段处理规则，即索引如何建立、索引类型、是否保存原始索引JSON文档、是否压缩原始JSON文档、是否需要分词处理、如何进行分词处理等。 
（5）在数据库中的增insert、删delete、改update、查search操作等价于ES中的增PUT/POST、删Delete、改_update、查GET.
## 简单使用ES

### 使用Docker安装Elasticsearch及其扩展
获取镜像，可以通过网络pull

``` javascript
docker image pull delron/elasticsearch-ik:2.4.6-1.0
```
修改elasticsearch的配置文件 elasticsearc-2.4.6/config/elasticsearch.yml第54行，更改ip地址为本机ip地址

``` javascript
network.host: 自己机器的IP地址
```
创建docker容器运行

``` javascript
docker run -dti --network=host --name=elasticsearch -v /home/python/elasticsearch-2.4.6/config:/usr/share/elasticsearch/config delron/elasticsearch-ik:2.4.6-1.0
```

### 使用haystack对接Elasticsearch
Haystack为Django提供了模块化的搜索。它的特点是统一的，熟悉的API，可以让你在不修改代码的情况下使用不同的搜索后端（比如 Solr, Elasticsearch, Whoosh, Xapian 等等）。

这里通过使用haystack来调用Elasticsearch搜索引擎。

#### 安装

``` javascript
pip install drf-haystack
pip install elasticsearch==2.4.1
```
drf-haystack是为了在REST framework中使用haystack而进行的封装（如果在Django中使用haystack，则安装django-haystack即可）。

#### 注册应用

``` javascript
INSTALLED_APPS = [
    ...
    'haystack',
]
```

#### 配置

``` javascript
# Haystack
HAYSTACK_CONNECTIONS = {
    'default': {
        'ENGINE': 'haystack.backends.elasticsearch_backend.ElasticsearchSearchEngine',
        # 端口号固定为9200
        'URL': 'http://es的IP:9200/',
        # 指定elasticsearch建立的索引库的名称
        'INDEX_NAME': '名称自定',
    },
}

# 当添加、修改、删除数据时，自动生成索引
HAYSTACK_SIGNAL_PROCESSOR = 'haystack.signals.RealtimeSignalProcessor'
```
注意：

HAYSTACK_SIGNAL_PROCESSOR 的配置保证了在Django运行起来后，有新的数据产生时，haystack仍然可以让Elasticsearch实时生成新数据的索引

#### 创建索引类

``` javascript
from haystack import indexes

from .models import SKU


class SKUIndex(indexes.SearchIndex, indexes.Indexable):
    """
    SKU索引数据模型类
    """
    text = indexes.CharField(document=True, use_template=True)

    def get_model(self):
        """返回建立索引的模型类"""
        return SKU

    def index_queryset(self, using=None):
        """返回要建立索引的数据查询集"""
        return self.get_model().objects.filter(is_launched=True)
```
在SKUIndex建立的字段，都可以借助haystack由elasticsearch搜索引擎查询。

其中text字段我们声明为document=True，表名该字段是主要进行关键字查询的字段， 该字段的索引值可以由多个数据库模型类字段组成，具体由哪些模型类字段组成，我们用use_template=True表示后续通过模板来指明。

在REST framework中，索引类的字段会作为查询结果返回数据的来源。

#### 在templates目录中创建text字段使用的模板文件
具体在templates/search/indexes/goods/sku_text.txt文件中定义

``` javascript
{{ object.name }}
{{ object.caption }}
```
此模板指明当将关键词通过text参数名传递时，可以通过sku的name、caption、id来进行关键字索引查询。

#### 手动生成初始索引

``` javascript
python manage.py rebuild_index
```

#### 创建序列化器
在goods/serializers.py中创建haystack序列化器

``` javascript
from drf_haystack.serializers import HaystackSerializer
from .search_indexes import SKUIndex

class SKUIndexSerializer(HaystackSerializer):
    """
    SKU索引结果数据序列化器
    """
    object = SKUSerializer(read_only=True)

    class Meta:
        index_classes = [SKUIndex]
        fields = (
            'text',  # 用于接收查询关键字
            'object'  # 用于返回查询结果
        )
```
下面的搜索视图使用SKUIndexSerializer序列化器用来检查前端传入的参数text，并且检索出数据后再使用这个序列化器返回给前端；

SKUIndexSerializer序列化器中的object字段是用来向前端返回数据时序列化的字段。

Haystack通过Elasticsearch检索出匹配关键词的搜索结果后，还会在数据库中取出完整的数据库模型类对象，放到搜索结果的object属性中，并将结果通过SKUIndexSerializer序列化器进行序列化。所以我们可以通过声明搜索结果的object字段以SKUSerializer序列化的形式进行处理，明确要返回的搜索结果中每个数据对象包含哪些字段。

#### 创建视图
在goods/views.py中创建视图

``` javascript
from drf_haystack.viewsets import HaystackViewSet
from .serializers import SKUIndexSerializer

class SKUSearchViewSet(HaystackViewSet):
    """
    SKU搜索
    """
    index_models = [SKU]

    serializer_class = SKUIndexSerializer
```
注意：
该视图会返回搜索结果的列表数据，所以可以为视图增加REST framework的分页功能。
我们在实现商品列表页面时已经定义了全局的分页配置，所以此搜索视图会使用全局的分页配置。

#### 定义路由
在goods/urls.py中通过REST framework的router来定义路由
``` javascript
from rest_framework.routers import DefaultRouter

...

router = DefaultRouter()
router.register('skus/search', views.SKUSearchViewSet, base_name='skus_search')

urlpatterns += router.urls
```

#### bug说明
如果在配置完haystack并启动程序后，出现如下异常，是因为drf-haystack还没有适配最新版本的REST framework框架
{% asset_img 3.jpg  %}
可以通过修改REST framework框架代码，补充_get_count函数定义即可

文件路径 虚拟环境下的 lib/python3.6/site-packages/rest_framework/pagination.py

``` javascript
def _get_count(queryset):
    """
    Determine an object count, supporting either querysets or regular lists.
    """
    try:
        return queryset.count()
    except (AttributeError, TypeError):
        return len(queryset)
```