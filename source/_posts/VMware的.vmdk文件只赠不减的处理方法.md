---
title: VMware的.vmdk文件只赠不减的处理方法
date: 2019-11-14 16:28:22
tags: VMware
categories: 环境安装
comments: true
description: 虚拟机
---

### 问题
VMware虚拟机的虚拟磁盘的大小会随着使用时间不断变大，而且只赠不减。即使在虚拟系统中删除了磁盘中的文件，虚拟磁盘的大小仍然不会变小。

### 解决方法
VMWare Tools中的 Shrink功能，和vmware-vdiskmanager工具。

1. 虚拟Windows系统，安装VMWare Tools，直接调用右下角图形工具Shrink。

2. 虚拟Linux系统，关注虚拟机，在VMWare的安装跟路径下，使用vmware-vdiskmanager工具。

如我的VMware安装在H盘，在windows的命令行中：

``` javascript
$ H:\>cd VMware

$ H:\VMware>vmware-vdiskmanager.exe -k "H:\UbuntuVMware\Ubuntu 64-bit\Ubuntu 64-bit.vmdk"
```

说明：H:\UbuntuVMware\Ubuntu 64-bit\Ubuntu 64-bit.vmdk是你指定需要shrink的.vmdk文件；另外，由于我的路径中有空格，所以路径用双引号包含，若路径无空格则可以忽略双引号。

如此瘦身之后，我的硬盘并未节省太多空间。原因是Ubuntu系统占用了空间，系统未释放，所有用工具逼它释放并不能达成目的。解决方案如下：

在虚拟Linux系统中，终端使用命令：

``` javascript
$ cat /dev/zero > zero.fill
```

执行完毕后，发现zero.fill非常大，使用命令将其删除

``` javascript
$ rm -f zero.fill
```

删除后再退出虚拟系统，在windows下再用vmware-vdiskmanager.exe去shrink文件*.vmdk。结束后我的电脑清理了大量空间。