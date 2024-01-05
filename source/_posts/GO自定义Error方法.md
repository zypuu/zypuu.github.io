---
title: GO自定义Error方法
date: 2020-12-27 11:10:22
tags: GO
categories: GO
comments: true
description: 解析go语言，自定义error的方法，用于业务使用
---

通过interface定义

``` javascript
type error interface {
    Error() string
}
```

自定义error

``` javascript
type Error struct {
    errCode uint8
}
func (e *Error) Error() string {
        switch e.errCode {
        case 1:
                return "file not found"
        case 2:
                return "time out"
        case 3:
                return "permission denied"
        default:
                return "unknown error"
         }
}
```