---
title: Git撤销回滚
date: 2019-11-05 17:19:03
tags: git
categories: Git代码管理
comments: true
description: git提交错误的回退处理，reset与revert
---

了解git如何撤销回滚，先了解git的工作流

## git工作流
完成一次完整的本地分支git提交工作，分为三个区域

工作区：即自己当前分支所修改的代码，git add xx 之前的！不包括 git add xx 和 git commit xxx 之后的。

暂存区：已经 git add xxx 进去，且未 git commit xxx 的。

本地分支：已经git commit -m xxx 提交到本地分支的。

 ![1](1.png)

代码回滚

在上传代码到远程仓库的时候，不免会出现问题，任何过程都有可能要回滚代码

## 如何回滚

分为以下几种场景

### 工作区的代码

``` javascript
git checkout ./a.txt   # 丢弃某个文件，或者
git checkout ./       # 丢弃全部
```
注意：git checkout – . 丢弃全部，也包括：新增的文件会被删除、删除的文件会恢复回来、修改的文件会回去。这几个前提都说的是，回到暂存区之前的样子。对之前保存在暂存区里的代码不会有任何影响。对commit提交到本地分支的代码就更没影响了。当然，如果你之前压根都没有暂存或commit，那就是回到你上次pull下来的样子了

### 代码git add到缓存区，并未commit提交

``` javascript
git reset HEAD .  或者
git reset HEAD a.txt
```

这个命令仅改变暂存区，并不改变工作区，这意味着在无任何其他操作的情况下，工作区中的实际文件同该命令运行之前无任何变化

### git commit到本地分支、但没有git push到远程

``` javascript
git log # 得到你需要回退一次提交的commit id
git reset --hard <commit_id>  # 回到其中你想要的某个版
或者
git reset --hard HEAD^  # 回到最新的一次提交
或者
git reset HEAD^  # 此时代码保留，回到 git add 之前
```

### git push把修改提交到远程仓库

reset和revert两种方式

#### 通过git reset是直接删除指定的commit

``` javascript
git log # 得到你需要回退一次提交的commit id
git reset --hard <commit_id>
git push origin HEAD --force # 强制提交一次，之前错误的提交就从远程仓库删除
```
#### 通过git revert是用一次新的commit来回滚之前的commit

``` javascript
git log # 得到你需要回退一次提交的commit id
git revert <commit_id>  # 撤销指定的版本，撤销也会作为一次提交进行保存
```




