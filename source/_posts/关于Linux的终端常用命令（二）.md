---
title: 关于Linux的常用基本命令（二）
copyright: true
date: 2018-01-24 17:39:04
tags: Linux
categories: 环境运维
comments: true
description: 关于linux系统ubantu终端的一些常用命令整理
---

<div>接上面《关于Linux的常用基本命令（一）》</div>[点这里](https://zypuu.github.io/2018/08/15/%E5%85%B3%E4%BA%8ELinux%E7%9A%84%E5%B8%B8%E7%94%A8%E5%9F%BA%E6%9C%AC%E5%91%BD%E4%BB%A4%EF%BC%88%E4%B8%80%EF%BC%89/)

#### 管道命令

``` javascript
 【命令1】 | 【命令2】 # 命令1的输出结果作为命令2的输入
```

#### 查找某个文件的文本

``` javascript
grep 【选项】 “字符串”  【文件】
选项：-i 忽略大小写
		  -n 显示匹配行及行号
		  -v 取反（显示余下的信息）
```
<div>例： ps -aux | grep ’mysql‘ 查看运行中的进程，带有mysql的进程</div>

#### 查找文件

``` javascript
find 【路径】 【选项】
选项：-name ’字符串‘ # 查找该文件名的文件
           -size +（-）’大小‘ # 查找文件大于（小于）多少的文件
		   -permission 权限 # 查找拥有该权限的文件
```

#### tar打包压缩文件与解压缩

``` javascript
tar 【选项】【打包后的文件名】【 要打包的文件名】
选项： -c 生成打包文件
			-v 显示进度
			-f 指定打包文件名称，所以f选项要放最后
			-x 拆包解包
			-z gzip格式压缩解压
			-j bzip2格式压缩解压
			c 指定目录
```

#### gzip格式压缩解压

``` javascript
gizp 【文件名】 # 压缩文件
gzip -d 【文件名】 # 解压缩文件
```

#### 查看命令位置
``` javascript
which
```

#### 查看当前用户登录

``` javascript
who # tty 本地登录 pts 远程登录
```

#### 授权当前用户执行命令

``` javascript
sudo # 管理员权限
```

#### 退出终端，回到上一用户，退出远程

``` javascript
exit
```

#### 软件卸载与安装

``` javascript
sudo apt-get install “安装包” # 安装
sudo apt-get remove “安装包” # 删除
sudo apt-get update “安装包” # 更新
```

#### 关机重启

``` javascript
shutdown -h now （或加时间） # 立即关机，或者多少时间后关机
				-r # 重启
```