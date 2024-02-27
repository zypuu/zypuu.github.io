---
title: 关于Mysql的sql注入问题
date: 2018-06-15 15:54:42
tags: Mysql
categories: 数据库
comments: true
description: Python中mysql的sql注入问题，以及如何预防sql注入。
---

## 什么是sql注入
所谓SQL注入，就是通过把SQL命令插入到Web表单提交或输入域名或页面请求的查询字符串，最终达到欺骗服务器执行恶意的SQL命令。具体来说，它是利用现有应用程序，将(恶意的)SQL命令注入到后台数据库引擎执行的能力，它可以通过在Web表单中输入(恶意)SQL语句得到一个存在安全漏洞的网站上的数据库，而不是按照设计者意图去执行SQL语句。

## 产生原因
SQL注入产生的原因：程序开发过程中不注意规范书写 sql语句和对特殊字符进行过滤，导致客户端可以通过全局变量POST 和GET 提交一些 sql语句正常执行。
比如：拼接字符串的方法

``` javascript
     sql = 'select * from goods where name="%s"' % find_name
    # 执行select语句，并返回受影响的行数：查询所有数据
	# findname为要输入的查询对象
```
输入 " or 1=1 or " (双引号也要输入)就会产生sql注入

## 后果
如果是让别人发现了你的这个注入的漏洞的话，你的整个数据库有可能直接获得管理员的权限，也就是说这个数据库又可以能掌握在别人的手里，里面的数据想查询就查询，想删除就删除，想对你数据库怎样就怎样，后果很严重。

## 预防sql注入

### 解决办法一：查询参数预防sql注入，预编译

例如：
``` javascript
1 args = (id, type)
2 cur.execute('select id, type ,name from xl_bugs where id = %s and type = %s', args )
```
使用如此参数带入方式，python会自动过滤args中的特殊字符，制止SQL注入的产生。

### 解决办法二：正则表达式过滤传入参数

检测SQL meta-characters的正则表达式 ：/(\%27)|(\’)|(\-\-)|(\%23)|(#)/ix

修正检测SQL meta-characters的正则表达式 ：/((\%3D)|(=))[^\n]*((\%27)|(\’)|(\-\-)|(\%3B)|(:))/i

典型的SQL 注入攻击的正则表达式 ：/\w*((\%27)|(\’))((\%6F)|o|(\%4F))((\%72)|r|(\%52))/ix

检测SQL注入，UNION查询关键字的正则表达式 ：/((\%27)|(\’))union/ix(\%27)|(\’)

检测MS SQL Server SQL注入攻击的正则表达式：/exec(\s|\+)+(s|x)p\w+/ix

### 解决办法三：前端js防sql注入

``` javascript
var url = location.search;
var re=/^\?(.*)(select%20|insert%20|delete%20from%20|count\(|drop%20table|update%20truncate%20|asc\(|mid\(|char\(|xp_cmdshell|exec%20master|net%20localgroup%20administrators|\"|:|net%20user|\|%20or%20)(.*)$/gi;
var e = re.test(url);
if(e) {
    alert("地址中含有非法字符～");
    location.href="error.asp";
}
```
前端验证只能起到一定作用，还需要后台参数化阻止SQL注入。

