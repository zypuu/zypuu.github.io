---
title: CKEditor富文本编辑器
date: 2018-07-02 20:21:03
tags: 富文本编辑器
categories: 环境安装
comments: true
description: CKEditor富文本编辑器的配置安装
---
在运营后台，运营人员需要录入并编辑模型类的详情信息，而这些信息不是普通的文本，可以是包含了HTML语法格式的字符串。为了快速简单的让用户能够在页面中编辑带格式的文本，富文本即具备丰富样式格式的文本。
![1](1.jpg)

## 安装

``` javascript
pip install django-ckeditor
```
## 添加应用

``` javascript
在INSTALLED_APPS中添加

INSTALLED_APPS = [
    ...
    'ckeditor',  # 富文本编辑器
    'ckeditor_uploader',  # 富文本编辑器上传图片模块
]
```
## 添加CKEditor配置
在settings.py中添加

``` javascript

# 富文本编辑器ckeditor配置
CKEDITOR_CONFIGS = {
    'default': {
        'toolbar': 'full',  # 工具条功能
        'height': 300,  # 编辑器高度
        # 'width': 300,  # 编辑器宽度
    },
}
CKEDITOR_UPLOAD_PATH = ''  # 上传图片保存路径，使用了FastDFS，所以此处设为' '
```
## 添加ckeditor路由

``` javascript
url(r'^ckeditor/', include('ckeditor_uploader.urls')),
```
## 为模型类添加字段

``` javascript
ckeditor.fields.RichTextField 不支持上传文件的富文本字段
ckeditor_uploader.fields.RichTextUploadingField 支持上传文件的富文本字段
```
在需要编辑的模型类的设置可以编辑的字段。
别忘了数据库迁移。

