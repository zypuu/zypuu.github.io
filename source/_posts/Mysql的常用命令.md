---
title: Mysql的常用命令
date: 2018-04-03 19:26:00
tags: Mysql
categories: 数据库
comments: true
description: mysql数据库的引擎区别，以及mysql的一些常用命令总结。
---
## Mysql两种引擎的区别

### Innodb引擎
Innodb引擎提供了对数据库ACID事务的支持，并且实现了SQL标准的四种隔离级别。该引擎还提供了行级锁和外键约束，它的设计目标是处理大容量数据库系统，它本身其实就是基于MySQL后台的完整数据库系统，MySQL运行时Innodb会在内存中建立缓冲池，用于缓冲数据和索引。但是该引擎不支持FULLTEXT类型的索引，而且它没有保存表的行数，当SELECT COUNT(*) FROM TABLE时需要扫描全表。当需要使用数据库事务时，该引擎当然是首选。由于锁的粒度更小，写操作不会锁定全表，所以在并发较高时，使用Innodb引擎会提升效率。但是使用行级锁也不是绝对的，如果在执行一个SQL语句时MySQL不能确定要扫描的范围，InnoDB表同样会锁全表。

### MyIASM引擎
MyIASM引擎没有提供对数据库事务的支持，也不支持行级锁和外键，因此当INSERT(插入)或UPDATE(更新)数据时即写操作需要锁定整个表，效率便会低一些。不过和Innodb不同，MyIASM中存储了表的行数，于是SELECT COUNT(*) FROM TABLE时只需要直接读取已经保存好的值而不需要进行全表扫描。如果表的读操作远远多于写操作且不需要数据库事务的支持，那么MyIASM也是很好的选择。

### 主要区别

1、MyIASM是非事务安全的，而InnoDB是事务安全的

2、MyIASM锁的粒度是表级的，而InnoDB支持行级锁

3、MyIASM支持全文类型索引，而InnoDB不支持全文索引

4、MyIASM相对简单，效率上要优于InnoDB，小型应用可以考虑使用MyIASM

5、MyIASM表保存成文件形式，跨平台使用更加方便

### 应用场景
1、MyIASM管理非事务表，提供高速存储和检索以及全文搜索能力，如果再应用中执行大量select操作，应该选择MyIASM 
2、InnoDB用于事务处理，具有ACID事务支持等特性，如果在应用中执行大量insert和update操作，应该选择InnoDB

## 常用命令

### 常用数据类型
1.整数：`int`
2.小数：`decinal（总位数，小数位数）`
3.字符串：`varchar（可变长度），char（固定长度）`
4.日期时间：`datetime`
5.枚举类型：`（enum）‘选择’`

### 数据库操作

#### 连接数据库

``` javascript
mysql -uroot -p
```

#### 退出

``` javascript
quit/exit
```

#### 查看版本

``` javascript
select version()；
```

#### 显示时间

``` javascript
select now()；
```

#### 查看当前使用数据库

``` javascript
select datebase（）；
```

#### 查看所有数据库

``` javascript
select databases();
```

#### 创建数据库

``` javascript
create database 数据库名；
```

#### 查看字符集

``` javascript
show create database 数据库名；
```

#### 删除数据库

``` javascript
drop database 数据库名；
```

#### 使用数据库

``` javascript
use 数据库名；
```

#### 数据库备份

``` javascript
mysql dump -uroot -p 数据库名 > 文件名.sql
```

#### 数据库恢复

``` javascript
mysql dump -uroot -p 数据库名 < 文件名.sql
```

#### 导入数据

``` javascript
source 文件名.sql
```

### 数据表的操作

#### 查看所有表

``` javascript
show tables;
```

#### 创建表

``` javascript
create table 表名(id int unsigned...)
```

#### 查看表结构

``` javascript
desc 表名
```

#### 查看字符集

``` javascript
show create table 表名;
```

#### 添加字段

``` javascript
alter table 表名 add 字段名 数据类型;
```

#### 修改字段

``` javascript
alter table 表名 modify 字段名 约束;
alter table 表名 change 原名 新名 约束；
```

#### 删除字段

``` javascript
alter table 表名 drop 字段名;
```

#### 删除表

``` javascript
drop table 表名;
```

### 数据的操作

#### 插入数据

``` javascript
insert into 表名 values (),(); # 数据，()按字段位置写入(),()是多行插入
```

#### 部分插入

``` javascript
insert into 表名（字段名） values ();
```

#### 修改数据

``` javascript
update 表名 set 字段名=‘’ where 条件；
```

#### 删除数据

``` javascript
delete from 表名 where 条件；
```

### 查询数据库

#### 查看表

``` javascript
select * from 表名
```

#### 查看字段数据，起名

``` javascript
select 表名.字段名 as '别名' from 表名
```

#### 去重复

``` javascript
select distinct 字段 from 表名；
select key from 表 group by key having count (*)>1;
```
并不会修改数据。

#### 条件查询

``` javascript
select * from 表名 where 字段名 > < >= <= != 或<>
# 也可以在条件里加逻辑 and 、or、  not（条件）、
```

#### 模糊查询

``` javascript
where like ‘小%’ # 以小字为开头的
% 替换任意个
_ 替换一个
```

#### 范围查询

``` javascript
where  字段名 in （）；# 具体值
not in
（not）between and # 区间查询
```

#### 判空

``` javascript
where 字段 is null （not null）；
```

#### 排序

``` javascript
select * from 表名 order by 字段 asc；升序 （desc 降序）；
```

#### 分组（按字段分组）

``` javascript
select 字段 from 表名 group by 字段；
```

#### 各个小组数据

``` javascript
select count（*）.字段一 【group_concat(字段二)】.字段一 from 表名 group by 字段一 having 条件；
```
按这个字段一分组，该组的统计，该组的字段二数据
注意： 这里的条件用having 不用where

#### 分页

``` javascript
select * from 表名 limit 0,5；# 第一个参数从第几页开始（显示个数*（第几页-1）），第二个参数显示数量
```
分页是为了限制查询，防止数据过大，limit放最后


### 聚合函数

#### 统计个数

``` javascript
select count（*） from 表名 where 条件；
```

#### 最大值

``` javascript
select max（字段）from 表名；
```

#### 最小值

``` javascript
select min（字段）from 表名；
```

#### 求和

``` javascript
select sum（字段） from 表名；
```

#### 平均

``` javascript
select round（avg（字段）） from 表名；# 保留小数
```

### 关联查询

#### 关联查询

``` javascript
select * from 表一 inner join 表二 on 表一.字段=表二.字段；
```
将表一的字段按表二的字段对应，合成一个表查询
后面的表是大表

#### 子查询

``` javascript
select * from表 where 字段 > (上一个表的查询结果)；
```

#### 自关联

``` javascript
select * from 表名 as 别名一 inner join 表名 as 别名二 on 别名一.字段 =别名二.字段
```

#### 外键关联

``` javascript
alter table 表一 addforeignkey（字段） references 表二（字段）；
```




### 拆表
已知表一
#### 创建表二

``` javascript
create table if not exists （字段属性）
```
if not exists 如果不存在

#### 将表一的数据分组

``` javascript
select 字段from 表一 group by 字段
```

#### 插入新表二

``` javascript
insert into 表二（字段） （第二步查询语句）
```
用子查询

#### 连接两个表，更新表一字段为表二的连接字段

``` javascript
update（select * from 表一 inner join 表二 on 表二.字段 = 表一.字段） set 表一.字段= 表二.字段
```

