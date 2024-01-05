---
title: 关于FastDFS文件分布式系统
date: 2018-07-16 19:15:15
tags: 文件存储
categories: 环境安装
comments: true
description: FastDFS简介，使用FastDFS进行文件存储
---
## FastDFS简介

### 什么是FastDFS

FastDFS 是一个开源的高性能分布式文件系统（DFS）。 它的主要功能包括：文件存储，文件同步和文件访问，以及高容量和负载平衡。主要解决了海量数据存储问题，特别适合以中小文件（建议范围：4KB < file_size <500MB）为载体的在线服务。

FastDFS 系统有三个角色：跟踪服务器(Tracker Server)、存储服务器(Storage Server)和客户端(Client)。

　　Tracker Server：跟踪服务器，主要做调度工作，起到均衡的作用；负责管理所有的 storage server和 group，每个 storage 在启动后会连接 Tracker，告知自己所属 group 等信息，并保持周期性心跳。

　　Storage Server：存储服务器，主要提供容量和备份服务；以 group 为单位，每个 group 内可以有多台 storage server，数据互为备份。

　　Client：客户端，上传下载数据的服务器，也就是我们自己的项目所部署在的服务器。
![1](1.jpg)
服务端两个角色:

Tracker: 管理集群，tracker 也可以实现集群。每个 tracker 节点地位平等。收集 Storage 集群的状态。
Storage: 实际保存文件， Storage 分为多个组，每个组之间保存的文件是不同的。每 个组内部可以有多个成员，组成员内部保存的内容是一样的，组成员的地位是一致的，没有 主从的概念。
### FastDFS存储策略
为了支持大容量，存储节点（服务器）采用了分卷（或分组）的组织方式。存储系统由一个或多个卷组成，卷与卷之间的文件是相互独立的，所有卷的文件容量累加就是整个存储系统中的文件容量。一个卷可以由一台或多台存储服务器组成，一个卷下的存储服务器中的文件都是相同的，卷中的多台存储服务器起到了冗余备份和负载均衡的作用。

在卷中增加服务器时，同步已有的文件由系统自动完成，同步完成后，系统自动将新增服务器切换到线上提供服务。当存储空间不足或即将耗尽时，可以动态添加卷。只需要增加一台或多台服务器，并将它们配置为一个新的卷，这样就扩大了存储系统的容量。

### 文件上传流程
FastDFS向使用者提供基本文件访问接口，比如upload、download、append、delete等，以客户端库的方式提供给用户使用。

Storage Server会定期的向Tracker Server发送自己的存储信息。当Tracker Server Cluster中的Tracker Server不止一个时，各个Tracker之间的关系是对等的，所以客户端上传时可以选择任意一个Tracker。
![2](2.jpg)
当Tracker收到客户端上传文件的请求时，会为该文件分配一个可以存储文件的group，当选定了group后就要决定给客户端分配group中的哪一个storage server。当分配好storage server后，客户端向storage发送写文件请求，storage将会为文件分配一个数据存储目录。然后为文件分配一个fileid，最后根据以上的信息生成文件名存储文件。

### 文件名组成

文件名如下：
![3](3.jpg)
组名：文件上传后所在的 storage 组名称，在文件上传成功后有 storage 服务器返回， 需要客户端自行保存。
虚拟磁盘路径：storage 配置的虚拟路径，与磁盘选项 store_path对应。如果配置了 store_path0 则是 M00，如果配置了 store_path1 则是 M01，以此类推。
数据两级目录：storage 服务器在每个虚拟磁盘路径下创建的两级目录，用于存储数据 文件。
文件名：与文件上传时不同。是由存储服务器根据特定信息生成，文件名包含:源存储 服务器 IP 地址、文件创建时间戳、文件大小、随机数和文件拓展名等信息。
## 简易FastDFS构建

### 使用docker安装FastDFS
拉取镜像

``` javascript
docker image pull delron/fastdfs
```
运行tracker

``` javascript
docker run -dti --network=host --name tracker -v /var/fdfs/tracker:/var/fdfs delron/fastdfs tracker
```
运行storage

``` javascript
docker run -dti --network=host --name storage -e TRACKER_SERVER=本机ip:22122 -v /var/fdfs/storage:/var/fdfs delron/fastdfs storage
```
然后可使用docker命令进行管理操作。

### FastDFS的Python客户端，Django使用FastDFS
参考：[点这里](https://github.com/jefforeilly/fdfs_client-py)

安装环境
下载安装包

``` javascript
pip install fdfs_client-py-master.zip
pip install mutagen
pip install requests
```
配置
我们在utils包下新建fastdfs包，client.conf配置文件放到这个目录中。
然后改一下其中的配置

``` javascript
base_path=FastDFS客户端存放日志文件的目录
tracker_server=运行tracker服务的机器ip:22122
```
上传文件需要先创建fdfs_client.client.Fdfs_client的对象，并指明配置文件，如

``` javascript
from fdfs_client.client import Fdfs_client
client = Fdfs_client('utils/fastdfs/client.conf')
```
通过创建的对象，执行上传文件的方法

``` javascript
from fdfs_client.client import Fdfs_client
client = Fdfs_client('utils/fastdfs/client.conf')
```

### 自定义Django文件存储系统
django自带文件存储系统，但是存储路径是本地，怎样将文件存储到FastDFS的服务器上呢
参考文档：[点这里](https://yiyibooks.cn/xx/Django_1.11.6/howto/custom-file-storage.html)

自定义文件存储系统的方法如下：
1）需要继承自django.core.files.storage.Storage，如

``` javascript
from django.core.files.storage import Storage

class FastDFSStorage(Storage):
```
2）支持Django不带任何参数来实例化存储类，也就是说任何设置都应该从django.conf.settings中获取

``` javascript
from django.conf import settings
from django.core.files.storage import Storage

class FastDFSStorage(Storage):
    def __init__(self, base_url=None, client_conf=None):
        if base_url is None:
            base_url = settings.FDFS_URL
        self.base_url = base_url
        if client_conf is None:
            client_conf = settings.FDFS_CLIENT_CONF
        self.client_conf = client_conf
```
3）存储类中必须实现_open()和_save()方法，以及任何后续使用中可能用到的其他方法。

``` javascript
_open(name, mode='rb')
# 被Storage.open()调用，在打开文件时被使用。
_save(name, content)
# 被Storage.save()调用，name是传入的文件名，content是Django接收到的文件内容，该方法需要将content文件内容保存。
# Django会将该方法的返回值保存到数据库中对应的文件字段，也就是说该方法应该返回要保存在数据库中的文件名称信息。
exists(name)
# 如果名为name的文件在文件系统中存在，则返回True，否则返回False。
url(name)
# 返回文件的完整访问URL
delete(name)
# 删除name的文件
listdir(path)
# 列出指定路径的内容
size(name)
# 返回name文件的总大小
```
4）需要为存储类添加django.utils.deconstruct.deconstructible装饰器
我们在utils/fastdfs目录中创建fdfs_storage.py文件，实现可以使用FastDFS存储文件的存储类如下
``` javascript
from django.conf import settings
from django.core.files.storage import Storage
from django.utils.deconstruct import deconstructible
from fdfs_client.client import Fdfs_client


@deconstructible
class FastDFSStorage(Storage):
    def __init__(self, base_url=None, client_conf=None):
        """
        初始化
        :param base_url: 用于构造图片完整路径使用，图片服务器的域名
        :param client_conf: FastDFS客户端配置文件的路径
        """
        if base_url is None:
            base_url = settings.FDFS_URL
        self.base_url = base_url
        if client_conf is None:
            client_conf = settings.FDFS_CLIENT_CONF
        self.client_conf = client_conf

    def _open(self, name, mode='rb'):
        """
        用不到打开文件，所以省略
        """
        pass

    def _save(self, name, content):
        """
        在FastDFS中保存文件
        :param name: 传入的文件名
        :param content: 文件内容
        :return: 保存到数据库中的FastDFS的文件名
        """
        client = Fdfs_client(self.client_conf)
        ret = client.upload_by_buffer(content.read())
        if ret.get("Status") != "Upload successed.":
            raise Exception("upload file failed")
        file_name = ret.get("Remote file_id")
        return file_name

    def url(self, name):
        """
        返回文件的完整URL路径
        :param name: 数据库中保存的文件名
        :return: 完整的URL
        """
        return self.base_url + name

    def exists(self, name):
        """
        判断文件是否存在，FastDFS可以自行解决文件的重名问题
        所以此处返回False，告诉Django上传的都是新文件
        :param name:  文件名
        :return: False
        """
        return False
```

### 在Django配置中设置自定义文件存储类
在settings.py文件中添加设置

``` javascript
# django文件存储
DEFAULT_FILE_STORAGE = 'utils.fastdfs.fdfs_storage.FastDFSStorage'

# FastDFS
FDFS_URL = '你的域名:8888/'  
FDFS_CLIENT_CONF = os.path.join(BASE_DIR, 'utils/fastdfs/client.conf')
```

### 添加image域名
在/etc/hosts中添加访问FastDFS storage服务器的域名
``` javascript
IP   image.域名
```