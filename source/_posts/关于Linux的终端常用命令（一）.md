---
title: 关于Linux终端的常用命令（一）
copyright: true
date: 2018-01-15 19:15:15
tags: Linux
categories: 环境运维
comments: true
description: 关于linux系统ubantu终端的一些常用命令整理
---

### 前言

----------
<div>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Linux由Unix发展而来，于1991年林纳斯（linus）发布，分为内核与发行版，内核（kernel）是系统的心脏，是运行程序和管理像磁盘和打印机等硬件设备的核心程序，主要做一些基本的，也是重要的操作。比如进程管理、内存管理、磁盘管理、驱动管理、电源管理、安全管理等。
Linux 内核版本又分为 稳定版 和 开发版，两种版本是相互关联，相互循环。
稳定版：具有工业级强度，可以广泛地应用和部署。新的稳定版相对于较旧的只是修正一些 bug 或加入一些新的驱动程序
开发版：由于要试验各种解决方案，所以变化很快
内核源码网址：[点这里](http://www.kernel.org)
</div>
<div>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Linux发行版通常包含了包括桌面环境、办公套件、媒体播放器、数据库等应用软件。<br>
主要有：ubantu，centos，redhat, debian等，这里主要是ubantu的基本常用命令。
</div>
### Linux终端命令基本使用
----------
<div>终端命令格式：Command 【-options（选项，可以配合使用）】【parameter（对象）】</div>


#### 1. 查看文件信息（在当前路径下输入即可查看当前路径文件）


``` javascript
ls -l # 查看详情
ls -a # 查看所有文件
ls -h # 配合-l显示文件大小
```

#### 2. 通配符，可以代替字符

``` javascript
* # 代表0个或多个任意字符
？ # 代表任意一个字符
```

 

#### 3. 清屏

``` javascript
clear
按键：ctrl +L
```

#### 4. 切换路径（分为相对路径和绝对路径，相对路径从当前目录开始；绝对路径从根目录（/）开始）

``` javascript
cd ./Desktop # .代表当前路径
cd ../ # ..代表上一级路径
```

#### 5. 显示当前绝对路径

``` javascript
pwd
```

#### 6. 创建目录

``` javascript
mkdir 目录名
mkdir a/b/c -p # 创建级联目录
```

#### 7. 创建文件（文件名指定后缀名）

``` javascript
touch 文件名
touch 文件1 文件2 文件3 # 创建多个文件
```

#### 8. 删除文件，目录

``` javascript
rm -i # 删除文件给予交互提示
rm -f # 强制删除
rm -r # 递归删除，删除目录
```

 

#### 9. 拷贝文件，目录

``` javascript
cp 【源文件名】【目标目录路径】# 拷贝文件不能在本目录下，不能重名
例： cp 1.txt ./a 将1.txt复制到当前目录的a目录下
cp 【源文件名】【目标文件名】# 拷贝并重命名
例： cp a.txt b.txt 复制a并命名为b
选项： -r 拷贝文件夹  -f 强制拷贝 -i交互提示

```

#### 10. 移动文件，文件夹

``` javascript
mv 【源文件名】【移动目标路径】# 移动目录不用-r 例：mv 1.txt ./a 将1文件移动到当前目录的a目录下
mv 【源文件名】【移动后文件名】# 重命名，不能重名 例： mv a.py b.py
```

 

#### 11. 树状显示目录

 

``` javascript
tree
```

#### 12. 查看历史命令

 

``` javascript
history # 显示历史命令
！数字 # 引用某一行命令 例：！20，引用20行命令
```

#### 13. 查看，写入文件内容

 

``` javascript
cat 【文件名】 # 查看 例：cat 1.txt
gedit 【文件名】# 写入 例 ： gedit 1.txt
```

#### 14. 重定向（将命令执行结果保存到另一个文件中）

 

``` javascript
> # 覆盖
>> # 追加 
例： cat 1.txt 2.txt > 3,txt 将1,2两个文件的内容重定向到3里，3.txt不存在则创建
```

#### 15. 分屏显示内容

 

``` javascript
more # 分屏显示文件内容，一般接到其他命令后，空格切换屏幕
```

