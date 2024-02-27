---
title: 关于docker的个人理解
date: 2018-08-01 15:19:59
tags: docker
categories: 环境运维
comments: true
description: 理解docker与镜像，如何使用docker来运行程序
---

### Docker通俗理解

什么是docker，docker翻译过来的名称就是容器，而容器是干什么用的，容器用来装东西的，就像一个集装箱，一个密闭的容器，不受外部的干扰，也无法干扰外部。
docker就是这么一个密闭的容器，将那些程序服务就放在docker里来运行。

### 为什么使用Docker
将程序软件安装在docker容器里去运行，本质上讲是一种虚拟技术，提到虚拟技术，就会想到虚拟机，那为什么要将程序安装到docker里运行，不直接在本机安装，使用虚拟技术，它又与虚拟机有和区别呢？

将程序直接安装在本机上，对于服务或者运行效率当然是最佳的体验，所以为什么使用容器，最主要原因就是成本原因，每一台主机都是有成本的，如果为了保证效率，每一台主机只跑部分服务，而需要多台主机的话，那成本就高了，当然有钱的另说，比如银行，追求省心稳定，一个服务器挂一台主机，性能用不完。但是一般的商业公司追求一定的经济性，一个主机只跑一些服务太浪费了，所以就出现把主机分开独立运行的手段---docker，降低服务器成本，还要保证一定的使用效率。

还有VM虚拟机，同样是虚拟技术，docker相对于虚拟机有何优点？
docker是直接调用原生系统资源，不像虚拟机是安装在操作系统上层层吃配置的软件服务。它比虚拟机更加强大，体积小，运行速度快，启动和关闭只需要几秒。相对于普通虚拟机来说，启动时间在分钟级别，占用内存大。所以这就是docker出现之后的优势。

### docker的应用场景

容器提供了隔离性，结论是，容器可以为各种测试提供很好的沙盒环境。并且，容器本 身就具有“标准性”的特征，非常适合为服务创建构建块。
Docker 的一些应用场景如下:
1.加速本地开发和构建流程，使其更加高效、更加轻量化。本地开发人员可以构建、 运行并分享 Docker 容器。容器可以在开发环境中构建，然后轻松的提交到测试环境中，并 最终进入生产环境。
2.能够让独立的服务或应用程序在不同的环境中，得到相同的运行结果。这一点在 面向服务的架构和重度依赖微型服务的部署由其实用。
3.用 Docker 创建隔离的环境来进行测试。例如，用 Jenkins CI 这样的持续集成工具 启动一个用于测试的容器。
4.Docker 可以让开发者先在本机上构建一个复杂的程序或架构来进行测试，而不是 一开始就在生产环境部署、测试。

### 镜像、容器与仓库

#### 镜像
创建虚拟机和docker 都必不可少的东西。  用过虚拟机的朋友都知道，创建一个虚拟机就先得下载操作系统的ISO镜像文件，然后通过镜像文件安装操作系统，和实体机类似，然后能在虚拟机中去安装各种软件。也可以将镜像当作容器的“源代码”。镜像体积很小，非常便携，易于分享、存储和更新。
Docker 容器启动是需要一些文件的， 而这些文件就可以称为 Docker 镜像。
#### 容器

通俗拿VM虚拟机和docker来举例，一个容器就类似于一个虚拟机，只不过在docker技术的术语上称为容器。这个容器装的就是我们部署的应用在运行，和虚拟机一样可以开机，关机，重启。docker称为容器的运行，关闭，重启。而且这个容器可以打包为镜像文件，类似虚拟机快照的文件，放在其它虚拟机上又可以保持原样能运行，docker也是如此，把容器打包为镜像文件，然后在新的服务器安装好的docker环境下导入进去，保持原来的状态能够运行。
容器是基于镜像启动起来的，容器中可以运行一个或多个进程。我们可以认为，镜像是Docker生命周期中的构建或者打包阶段，而容器则是启动或者执行阶段。 容器基于镜像启动，一旦容器启动完成后，我们就可以登录到容器中安装自己需要的软件或者服务。

#### 仓库
如果你使用过git和github就很容易理解Docker的仓库概念。Docker 仓库的概念跟Git 类似，注册服务器可以理解为 GitHub 这样的托管服务。

Docker 仓库是用来包含镜像的位置，Docker提供一个注册服务器（Register）来保存多个仓库，每个仓库又可以包含多个具备不同tag的镜像。Docker运行中使用的默认仓库是 Docker Hub 公共仓库。

仓库支持的操作类似git，当用户创建了自己的镜像之后就可以使用 push 命令将它上传到公有或者私有仓库，这样下次在另外一台机器上使用这个镜像时候，只需要从仓库上 pull 下来就可以了。.

### docker、容器、镜像的安装与操作

#### docker的安装与操作
添加Docker官方GPG key
``` javascript
sudo apt-key add gpg
```
安装Docker稳定版
``` javascript
sudo dpkg -i docker-ce_17.03.2~ce-0~ubuntu-xenial_amd64.deb
```
检查Docker是否安装正确
``` javascript
sudo docker run hello-world
```
为了避免每次命令都输入sudo，可以设置用户权限，注意执行后须注销重新登录
``` javascript
sudo usermod -a -G docker $USER
```
安装完成Docker后，默认已经启动了docker服务，如需手动控制docker服务的启停，可执行如下命令

``` javascript
# 启动docker
sudo service docker start

# 停止docker
sudo service docker stop

# 重启docker
sudo service docker restart
```

#### 镜像操作
列出镜像

``` javascript
docker image ls
```
拉取镜像。即从官方仓库docker hub上拉取。[docker hub](https://hub.docker.com/)

``` javascript
docker image pull library/hello-world
```
由于 Docker 官方提供的 image 文件，都放在library组里面，所以它的是默认组，可以省略，hello world 是镜像文件名字。

删除镜像

``` javascript
docker image rm 镜像名或镜像id
```

#### 容器操作
创建容器

``` javascript
docker run [option] 镜像名 [向启动容器中传入的命令]
```
-i 表示以“交互模式”运行容器
-t 表示容器启动后会进入其命令行。加入这两个参数后，容器创建就能登录进去。即 分配一个伪终端。
--name 为创建的容器命名
-v 表示目录映射关系(前者是宿主机目录，后者是映射到宿主机上的目录，即 宿主机目录:容器中目录)，可以使 用多个-v 做多个目录或文件映射。注意:最好做目录映射，在宿主机上做修改，然后 共享到容器上。
-d 在run后面加上-d参数,则会创建一个守护式容器在后台运行(这样创建容器后不 会自动登录容器，如果只加-i -t 两个参数，创建后就会自动进去容器)。
-p 表示端口映射，前者是宿主机端口，后者是容器内的映射端口。可以使用多个-p 做多个端口映射
-e 为容器设置环境变量
--network=host 表示将主机的网络环境映射到容器中，容器的网络与主机相同
例：
交互式容器

``` javascript
docker run -it --name=myubuntu ubuntu /bin/bash
```
可以执行linux命令。
守护式容器

``` javascript
docker run -dit --name=myubuntu2 ubuntu
```
如果对于一个需要长期运行的容器来说，我们可以创建一个守护式容器。在容器内部exit退出时，容器也不会停止。

查看容器

``` javascript
# 列出本机正在运行的容器
docker container ls

# 列出本机所有容器，包括已经终止运行的
docker container ls --all
```
停止与启动容器

``` javascript
# 停止一个已经在运行的容器
docker container stop 容器名或容器id

# 启动一个已经停止的容器
docker container start 容器名或容器id

# kill掉一个已经在运行的容器
docker container kill 容器名或容器id
```
删除容器

``` javascript
docker container rm 容器名或容器id
```

#### 将容器保存为镜像，备份迁移
将容器保存为镜像
``` javascript
docker commit 容器名 镜像名
```
将镜像打包成文件，拷贝给别人使用

``` javascript
docker save -o 保存的文件名 镜像名
```
拿到镜像文件加载到本地

``` javascript
docker load -i ./ubuntu.tar
```
当前目录下的ubantu为例

