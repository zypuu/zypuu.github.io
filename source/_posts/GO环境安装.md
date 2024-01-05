---
title: GO环境安装
date: 2020-12-19 13:09:22
tags: GO
categories: 环境安装
comments: true
description: go服务本地开发环境安装，及相关环境参数，go mod相关
---

## 安装包下载、安装

去官网下载go安装包即可，根据自己的操作系统。

提取到 /usr/local 目录，在 /usr/local/go 中创建Go目录树

``` javascript
tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz
```
sudo运行，或者root用户

## 环境变量设置

要将 /usr/local/go/bin 添加到 PATH 环境变量， 你需要将此行添加到你的 /etc/profile（全系统安装）或 $HOME/.profile 文件中

``` javascript
export PATH=$PATH:/usr/local/go/bin
```

如果安装到其他位置，则需要设置GOROOT

``` javascript
export GOROOT=$HOME/go
export PATH=$PATH:$GOROOT/bin
```

## 相关环境变量参数

``` javascript
go env
go version
```

go env可查看go的环境变量参数，go version 可查看go的版本

### GO111Module
go 1.11才有的特性

``` javascript
export GO111MODULE=on # 开启GoModule特性
```
GO111MODULE解释, 当为on时则使用Go Modules,go 会忽略 $GOPATH和 vendor文件夹,只根据go.mod下载依赖。

当为 off时则不适用新特性 Go Modules支持，它会查找 vendor目录和 $GOPATH来查找依赖关系，也就是继续使用“GOPATH模式”。

当为 auto时或未设置时则根据当前项目目录下是否存在 go.mod文件或 $GOPATH/src之外并且其本身包含go.mod文件时才会使用新特性 Go Modules模式，

并且auto为 GO111MODULE的默认值。

### GOPATH

表示go的工作目录，这个目录指定了需要从哪个地方寻找GO的包、可执行程序等，这个目录可以是多个目录表示

### GOROOT

表示的是go语言编译、工具、标准库等的安装路径。

在Linux下设置GOROOT目录：

``` javascript
export GOROOT=$HOME/go
```

### GOPROXY

简单来说就是一个代理，让我们更方便的下载哪些由于墙的原因而导致无法下载的第三方包，

http://proxy.golang.org 在中国无法访问，故而建议使用 http://goproxy.cn 作为替代

## GO MOD

### 初始化模块
go mod init <项目模块名称>

### 依赖关系处理 ,根据go.mod文件
go mod tidy

### 将依赖包复制到项目下的 vendor目录。
go mod vendor
如果包被屏蔽(墙),可以使用这个命令，随后使用go build -mod=vendor编译

### 显示依赖关系
go list -m all

### 显示详细依赖关系
go list -m -json all

### 下载依赖
go mod download [path@version]
[path@version]是非必写的
