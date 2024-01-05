---
title: Git rebase 理解及使用
date: 2020-06-17 16:27:20
tags: git
categories: Git代码管理
comments: true
description: git 合并分支，提交历史相关处理，如何保证一条干净的master分支提交历史
---

## 什么是git rebase

官方描述

``` javascript
“git-rebase: Forward-port local commits to the updated upstream head”— git doc
```
翻译一下，主要用在从上游分支获取最新commit信息，并有机的将当前分支和上游分支进行合并

PS： gitrebase并不会删除老的提交，也就是说你在对某个分支执行了rebase操作之后，老的提交仍然会存放在.git文件夹的objects目录下

## 使用rebase意义

1.使用git log时，可以看到一个更整洁commit 历史树；

2.对于git工作流，commit数要多而有意义，这样review 代码速度加快，而且commit 都是有意义的，而且利于回退；

3.很多人的分支提交历史经常是fix，fix, fix agian,好的commit应该反映出项目的一步步开发。

## 工作流程及原理：变基

![1](1.png)

 如上图所示，C1是线上的版本，在C1的代码上线了之后我们发现了一个bug，于是我们checkout了一个叫做bugFix的分支。与此同时还有新的功能在开发，新的功能提交到了master之后形成了节点C2。这个时候我们在bugFix分支当然可以merge master这没有什么问题，但是也可以rebase master，rebase之后整棵git树会变成这样：

![2](2.png)

 这个结果就好像是我们先到了C2然后checkout出了bugFix分支，然后在bugFix分支上将之前写过的代码重新写了一遍。这样的操作就是变基，当我们rebase了之后再提交合并请求我们的合并记录里面会非常干净，没有多余merge的信息。

操作命令：
``` javascript
 	git checkout bugFix
	git rebase master
	git checkout master
	git merge bugFix
```
前两步也可以直接写，直接在master分支执行
``` javascript
 	git rebase master bugFix
```
它会先checkout到bugFix分支然后执行rebase master的操作，之后我们再checkout到master进行合并即可

更复杂一点
![3](3.png)

master是正常的线上分支，在C2节点处代码上线。上线之后继续开发新的需求checkout了新的分支feature，与此同时master也经过了一些合并，合并了另外的一些改动到了C4节点。之后新的分支feature开发完成了一个重要性能提升的改动C5，这时，我们发现了线上代码的一个bug并且性能不佳，我们需要紧急修复。于是在C5处checkout了新的分支bugFix，我们在bugFix分支当中修复了bug，想要发布上线。
这时候feature分支继续开发到了C6节点，仍然没有开发完成，也没有经过系统测试。所以我们并不希望C6的代码发布上线，我们希望合并进入master的代码之后C5，C7和C8。我们只需要在bugFix分支rebase到master，然后修复冲突之后提交。提交完成了之后，我们再checkout到master把bugFix分支merge进来
结果如下：

![4](4.png)

## 使用场景

### 远程代码同步使用 pull --rebase

当我们项目多人在同一个分支开发时，不可避免在你要提交代码之前有人已往远程仓库提交代码。当我们push时，提示你先pull，如果我们直接pull，有冲突的情况我们需要解决冲突，没有冲突的情况自动合并，不管哪种情况我们都会产生一条新的提交记录

![5](5.png)
``` javascript
 	git pull --rebase
```
 可以避免这一条记录产生

如果是两人同时修改一个文件而产生了冲突，解决冲突后
``` javascript
    git add .
 	git rebase --continue
```
通过git log查看，会发现修改会放到最新的修改之后，一条线顺延，不会有多余的commit记录

``` javascript
    git pull --rebase 当需要进行pull代码时候，使用这个命令，可以不生成merge branch 的log

	git rebase --continue 当冲突问题解决之后可以使用git add .再使用该命令继续完成

	git rebase --abort 当前的commit会回到rebase操作之前的状态。

	git rebase --skip 如果你想丢弃该条引起冲突的commits，可以使用该命令，慎用；
```

git pull实际执行
``` javascript
    git pull的默认行为是git fetch + git merge
	git pull --rebase则是git fetch + git rebase.
```

### 整合分支

一般的merge工作流程是这样的：

在当前你的master分支切出一个新分支test,增加一个文件，而此时master上有个小东西需要直接改一下，你接下来切回master分支，你修改了一些提交commit 并push远程。之后回到test分支继续开发完成，之后commit提交"测试合并",push远程。

接下来，test分支没问题了，你需要合并test分支到master。通常我们最多的是在master分支上使用git merge test 命令，这时master会产生一条新的commit记录，默认叫 Merge branch 'test'.你可以修改它，之后push远程。

整合分支要显示整洁的代码提交记录

``` javascript
    git checkout -b test    #在test 的 branch 上添加一个文件
    git commit
	git rebase master  之后回master分支，
	git merge test进行一次快进合并.
```
使用git log 查看test上的commit记录，和上面直接使用merge的方式不同，会少一条merge记录。

这两种整合方法的最终结果没有任何区别，但是变基使得提交历史更加整洁


### 合并多个commit

在一个分支为了解决一个问题，进行了多次commit，则会有多条commit记录，显得杂而乱

``` javascript
    git rebase -i [startpoint] [endpoint]
    其中-i的意思是--interactive，即弹出交互式的界面让用户编辑完成合并操作，
    [startpoint] [endpoint]则指定了一个编辑区间，如果不指定[endpoint]，则该区间的终点默认是当前分支HEAD所指向的commit(注：该区间指定的是一个前开后闭的区间)
    git rebase -i f4c477^ （使用^表示从该commitid开始）
```
或者
``` javascript
   git rebase -i HEAD~3
```
会有如下的交互提示，进入编辑页面

![6](6.png)

pick：保留该commit（缩写:p）
reword：保留该commit，但我需要修改该commit的注释（缩写:r）
edit：保留该commit, 但我要停下来修改该提交(不仅仅修改注释)（缩写:e）
squash：将该commit和前一个commit合并（缩写:s）
fixup：将该commit和前一个commit合并，但我不要保留该提交的注释信息（缩写:f）
exec：执行shell命令（缩写:x）
drop：我要丢弃该commit（缩写:d）

然后对commit内容进行修改，对需要合并的commit进行s操作合并，缩写即可

：wq保存后，会进入另一个编辑页面

![7](7.png)

编辑commit信息，然后保存

### git rebase --onto A B C 的用法

A : 是一个分支名称（代表此分支的 HEAD）或者是一个 commit_id (此 id 不在 C 上)      
B : 一个分支名称（此分支与 C 有共同的祖先 commit）或者是一个 commit_id (此 id 在 C 上)      
C : 一个分支名称

命令的作用：       
1. 首先会执行 git checkout 切换到 C       
2.  将 B 到 C(HEAD) 之间所标识范围内的提交写到一个临时文件中 ，若B 为分支名称，则找 B 与 C 共同的祖先 commit，则为此 commit 到 C(HEAD) 之间所标识范围内的提交。       
3.  将当前分支强制重置（git reset --hard）到 A       
4.  从2中临时文件的提交列表中，一个一个将提交按照顺序重新提交到重置之后的分支上        
注：       
1. 如果遇到提交已经在分支中包含，跳过该提交。       
2. 如果在提交过程遇到冲突，衍合过程暂停。用户解决冲突后，执行 git rebase --continue 继续变基操作。或者执行 git rebase --skip 跳过此提交。或者执行 git rebase --abort 就此终止变基操作切换到变基前的分支上。       
3. 衍合操作结束后，当前分支为 C



## 注意-使用法则

不要通过rebase对任何已经提交到公共仓库中的commit进行修改,自己一个人玩的分支除外.

只要你把变基命令当作是在推送前清理提交使之整洁的工具，并且只在从未推送至共用仓库的提交上执行变基命令，就不会有事。假如在那些已经被推送至共用仓库的提交上执行变基命令，并因此丢弃了一些别人的开发所基于的提交，那你就麻烦了.