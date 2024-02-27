---
title: 关于ubuntu18下docker无法启动服务的问题解决
date: 2018-10-14 10:08:22
tags: docker
categories: 环境运维
comments: true
description: docker服务启动问题
---

### 问题

近日在最新版本的Ubuntu下安装docker，配置指定安全参数ip（`--insecure -registry`），并启动docker服务的时候，遇到无法启动的问题，通过查看启动日志
查看启动日志
``` javascript
systemctl status docker
```
查看docker.service的启动日志，发现如下错误

``` javascript
Failed to start Docker Application Container Engine
```

### 解决方案

#### 修改docker启动默认配置文件

``` javascript
vim etc/default/docker
```
vim打开这个文件，找到

``` javascript
DOCKER_OPTS = ......
```
在这一行打开注释，添加自己的安全参数，ip等信息，然后保存退出。

#### 修改docker启动服务文件

``` javascript
vim  /lib/systemd/system/docker.service
```
vim打开docker启动服务文件

在里面添加指定环境文件

``` javascript
EnvironmentFile = -/etc/default/docker # 就是第一步修改的文件
```
然后下一行找到

``` javascript
Execstart = /usr/bin dockerd -H fd:// $DOCKER_OPTS 
```
即加载第一步环境文件里的DOCKER_OPTS，自己指定的insecure registry.

#### 删除其他默认的加载

``` javascript
rm /etc/systemd/system/docke.service.d
rm /etc/docker/daemon.json
```
删除这两个文件，不删除，会加载这两个文件里的配置

#### 重新启动docker服务
重新启动
``` javascript
systemctl daemon -reload
systemctl restart docker
```
查看docker进程

``` javascript
ps -ef | grep docker
```