---
title: Git常用命令及分支
date: 2018-05-21 20:21:03
tags: git
categories: Git代码管理
comments: true
description: git代码管理，分支，常用命令
---

## git分支
![1](1.jpg)
从上图可以看到主要包含下面几个分支：

master: 主分支，主要用来版本发布。
develop：日常开发分支，该分支正常保存了开发的最新代码。
feature：具体的功能开发分支，只与 develop 分支交互。
release：release 分支可以认为是 master 分支的未测试版。比如说某一期的功能全部开发完成，那么就将 develop 分支合并到 release 分支，测试没有问题并且到了发布日期就合并到 master 分支，进行发布。
hotfix：线上 bug 修复分支。

### 主分支
主分支包括 master 分支和 develop 分支。master 分支用来发布，HEAD 就是当前线上的运行代码。develop 分支就是我们的日常开发。使用这两个分支就具有了最简单的开发模式：develop 分支用来开发功能，开发完成并且测试没有问题则将 develop 分支的代码合并到 master 分支并发布。

### 辅助分支
feature 分支
release 分支
hotfix 分支
通过这些分支，我们可以做到：团队成员之间并行开发，feature track 更加容易，开发和发布并行以及线上问题修复。

#### Feature 分支
feature 分支用来开发具体的功能，一般 fork 自 develop 分支，最终可能会合并到 develop 分支。比如我们要在下一个版本增加功能1、功能2、功能3。那么我们就可以起三个feature 分支：feature1，feature2，feature3。（feature 分支命名最好能够自解释，这并不是一种好的命名。）随着我们开发，功能1和功能2都被完成了，而功能3因为某些原因完成不了，那么最终 feature1 和 feature2 分支将被合并到 develop 分支，而 feature3 分支将被干掉。

#### Release 分支
我们最初所有的开发工作都在 develop 分支上，当我们这一期的功能开发完毕的时候，我们基于 develop 分支开一个新的 release 分支。这个时候我们就可以对 release 分支做统一的测试了，另外做一些发布准备工作：比如版本号之类的。如果测试有问题的话，我们将直接在 release 分支上修改，然后将修改合并到 develop 分支上。

#### Hotfix 分支
顾名思义，hotfix 分支用来修复线上 bug。当线上代码出现 bug 时，我们基于 master 分支开一个 hotfix 分支，修复 bug 之后再将 hotfix 分支合并到 master 分支并进行发布，同时 develop 分支作为最新最全的代码分支，hotfix 分支也需要合并到 develop 分支上去。仔细想一想，其实 hotfix 分支和 release 分支功能类似。hotfix 的好处是不打断 develop 分支正常进行，

## git基本命令
1）git add 将想要快照的内容写入缓存区
2）git status -s "AM" 状态的意思是，这个文件在我们将它添加到缓存之后又有改动
3）git commit -m '第一次版本提交' -m选项添加备注信息
4）git clone url 使用 git clone 拷贝一个 Git 仓库到本地
5）git diff 查看执行 git status 的结果的详细信息
　　尚未缓存的改动：git diff
　　查看已缓存的改动： git diff --cached
　　查看已缓存的与未缓存的所有改动：git diff HEAD
　　显示摘要而非整个 diff：git diff --stat
6）git commit -a 跳过git add 提交缓存的流程 
7）git reset HEAD 用于取消已缓存的内容
8）git rm file 
　　git rm 会将条目从缓存区中移除。这与 git reset HEAD 将条目取消缓存是有区别的。
　　"取消缓存"的意思就是将缓存区恢复为我们做出修改之前的样子。
　　默认情况下，git rm file 会将文件从缓存区和你的硬盘中（工作目录）删除。
9）git mv 重命名磁盘上的文件 如 git mv README README.md

10）git push -u origin master 提交代码

## git分支管理
查看本地分支：$ git branch

查看远程分支：$ git branch -r

创建本地分支：$ git branch [name] ----注意新分支创建后不会自动切换为当前分支

切换分支：$ git checkout [name]

创建新分支并立即切换到新分支：$ git checkout -b [name]

删除分支：$ git branch -d [name] ---- -d选项只能删除已经参与了合并的分支，对于未有合并的分支是无法删除的。如果想强制删除一个分支，可以使用-D选项

合并分支：$ git merge [name] ----将名称为[name]的分支与当前分支合并

创建远程分支(本地分支push到远程)：$ git push origin [name]

删除远程分支：$ git push origin :heads/[name] 或 $ gitpush origin :[name] 

## git仓库相关命令
检出仓库：        $ git clone git://github.com/jquery/jquery.git

查看远程仓库：$ git remote -v

添加远程仓库：$ git remote add [name] [url]

删除远程仓库：$ git remote rm [name]

修改远程仓库：$ git remote set-url --push [name] [newUrl]

拉取远程仓库：$ git pull [remoteName] [localBranchName]

推送远程仓库：$ git push [remoteName] [localBranchName]


如果想把本地的某个分支test提交到远程仓库，并作为远程仓库的master分支，或者作为另外一个名叫test的分支，如下：

$git push origin test:master         // 提交本地test分支作为远程的master分支

$git push origin test:test              // 提交本地test分支作为远程的test分支

## git版本相关操作命令
查看版本：$ git tag

创建版本：$ git tag [name]

删除版本：$ git tag -d [name]

查看远程版本：$ git tag -r

创建远程版本(本地版本push到远程)：$ git push origin [name]

删除远程版本：$ git push origin :refs/tags/[name]

合并远程仓库的tag到本地：$ git pull origin --tags

上传本地tag到远程仓库：$ git push origin --tags

创建带注释的tag：$ git tag -a [name] -m 'yourMessage'


## 提取远程代码
1）git fetch　　从远程仓库下载新分支与数据
2)）git pull　　从远端仓库提取数据并尝试合并到当前分支



