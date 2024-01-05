---
title: Git查看文件历史
date: 2019-03-04 21:21:03
tags: git
categories: Git代码管理
comments: true
description: git代码管理，分支，常用命令
---

#### 显示commit历史，以及每次commit发生变更的文件

``` javascript
 git log --stat
```

#### 搜索提交历史，根据关键词

``` javascript
git log -S [keyword]
```

#### 显示某个commit之后的所有变动，每个commit占据一行

``` javascript
git log [tag] HEAD --pretty=format:%s
```

#### 显示某个commit之后的所有变动，其"提交说明"必须符合搜索条件

``` javascript
git log [tag] HEAD --grep feature
```

#### 显示某个文件的版本历史，包括文件改名

``` javascript
git log --follow [file]
git whatchanged [file]
```

#### 显示指定文件相关的每一次diff

``` javascript
git log -p [file]
```

#### 显示过去5次提交

``` javascript
git log -5 --pretty --oneline
```

#### 显示所有提交过的用户，按提交次数排序

``` javascript
git shortlog -sn
```

#### 显示指定文件是什么人在什么时间修改过

``` javascript
 git blame [file]
```

#### 显示暂存区和工作区的代码差异

``` javascript
git diff
```

#### 显示暂存区和上一个commit的差异

``` javascript
git diff --cached [file]
```

#### 显示工作区与当前分支最新commit之间的差异

``` javascript
git diff HEAD
```

#### 显示两次提交之间的差异

``` javascript
git diff [first-branch]...[second-branch]
```

#### 显示今天你写了多少行代码

``` javascript
git diff --shortstat "@{0 day ago}"
```

#### 显示某次提交的元数据和内容变化

``` javascript
git show [commit]
```

#### 显示某次提交发生变化的文件

``` javascript
git show --name-only [commit]
```

#### 显示某次提交时，某个文件的内容

``` javascript
git show [commit]:[filename]
```

#### 显示当前分支的最近几次提交

``` javascript
git reflog
```

#### 从本地master拉取代码更新当前分支：branch 一般为master

``` javascript
git rebase [branch]
```

