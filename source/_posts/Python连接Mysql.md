---
title: Python连接Mysql
date: 2018-05-07 15:55:17
tags: Mysql
categories: 数据库
comments: true
description: 通过python操作mysql
---
通过python操作mysql，面向对象的编程思想
## 导入包

``` javascript
from pymysql import *
```
## 面向对象封装

### init初始化方法
创建连接，建立游标对象
``` javascript
class JD(object):
    def __init__(self):
        # 　1创建链接对象
        self.conn = connect(host='主机名', port=3306, database='数据库名', user='账户名', password='密码',charset='utf8')

        # 2 创建游标对象
        self.cs = self.conn.cursor()
```

### del方法
关闭游标，关闭连接

``` javascript
def __del__(self):
        # 5 关闭
        self.cs.close()
        self.conn.close()
```

### sql语句执行方法

``` javascript
def my_execute_sql(self,sql):
        """执行ｓｑｌ语句"""
        self.cs.execute(sql)

        # 4 获取数据
        content = self.cs.fetchall()
```

### 写sql语句
例：
``` javascript
def show_all_goods(self):
        """显示所有的商品信息"""
        sql = "select * from goods;"

        self.my_execute_sql(sql)
```

### 运行

``` javascript
def run(self):
      self.show_all_goods()
```

