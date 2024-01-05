---
title: Git的reset与revert的区别
date: 2019-12-12 13:19:20
tags: git
categories: Git代码管理
comments: true
description: 关于git的在处理需要回退代码的场景时，reset与revert的区别，以及如何正确的处理错误提交，避免错误
---

## git的head理解
使用git的每次提交，Git都会自动把它们串成一条时间线，这条时间线就是一个分支。如果没有新建分支，那么只有一条时间线，即只有一个分支，在Git里，这个分支叫主分支，即master分支。有一个HEAD指针指向当前分支（只有一个分支的情况下会指向master，而master是指向最新提交）

## reset操作

### 原理

git reset的作用是修改HEAD的位置，即将HEAD指向的位置改变为之前存在的某个版本

![1](1.png)

reset之后，目标版本之后的版本会被删除，更新为reset的版本

![2](2.png)

### 使用场景

如果想恢复到之前某个提交的版本，且那个版本之后提交的版本我们都不要了，就可以用这种方法

### 操作
git log 查看当前分支版本号，commit ID

``` javascript
git log -p
```

如下图所示，选择要回退的commit ID

![3](3.png)

``` javascript
git reset --hard 版本号
```

然后提交更改
``` javascript
git push -f
```
PS： “git push”会报错，因为我们本地库HEAD指向的版本比远程库的要旧

强推则回退成功

## revert

### 原理

 git revert是用于“反做”某一个版本，以达到撤销该版本的修改的目的。比如，我们commit了三个版本（版本一、版本二、 版本三），突然发现版本二不行（如：有bug），想要撤销版本二，但又不想影响撤销版本三的提交，就可以用 git revert 命令来反做版本二，生成新的版本四，这个版本四里会保留版本三的东西，但撤销了版本二的东西

 ![4](4.png)

 ![5](5.png)

### 适用场景
如果我们想撤销之前的某一版本，但是又想保留该目标版本后面的版本，记录下这整个版本变动流程，就可以用这种方法。

### 操作

git log 查看当前分支版本号，commit ID

``` javascript
git log -p
```

选择要反做的版本号，撤销该版本的修改

``` javascript
git revert -n 版本号
```

PS： 这里可能会出现冲突，那么需要手动修改冲突的文件。而且要git add 文件名。

提交反做的内容

``` javascript
git commit -m "新提交说明" 
```

这时可以git log查看本地的版本信息，会发现新增一个版本

git push推上去

``` javascript
git push
```

反做成功

## 个人理解

reset： 回滚“到”某个版本

revert： 回滚某个版本
