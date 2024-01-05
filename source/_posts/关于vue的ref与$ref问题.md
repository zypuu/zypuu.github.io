---
title: 关于vue的ref与$ref的问题
date: 2020-03-29 21:09:43
tags: Vue
categories: 前端
comments: true
description: 前端页面的一问题处理
---

### 释义

#### refs

vm.$refs，一个对象，object，持有已注册过ref的所有子组件。

#### ref

ref用来给元素或子组件注册引用信息。引用信息将会注册在父组件的refs上。如果普通dom上使用，引用指向的就是dom元素，如果用在子组件上，引用就指向子组件示例。



#### 注意问题：ref属于非响应式

ref本身是作为渲染结果被创建的，在初始渲染的时候并不能访问他们，因为还不存在，会报错。而$refs也不是响应式的，所以同样不能访问，要注意。

#### 开发中的实例问题

``` javascript
<el-form ref="booksForm" onsubmit="return false" :model="form" :inline="true" :rules="rules_search">
<el-form-item prop="books_ids">
        <el-input
          style="width: 300px;"
          placeholder="ID搜索,逗号英文分隔"
          v-model="form.books_ids"
          clearable
        ></el-input>
      </el-form-item>
```
在页面表单中绑定了ref，el-input是一个搜索输入框，如果不输入值，则默认搜索全部数据。

但是在搜索的时候需要在前端进行验证，检验是否是数字

``` javascript
 getBooks() {
      this.$refs['booksForm'].validate(valid => {
        if (valid) {.....}

# ......中为通过api，查询数据库的逻辑，然后返回数据
```
看上面代码，是通过$ref绑定调用，进行的验证。

但是在页面刚进入，对象实例在被创建前，也就是在vue对象创建的钩子函数中，需要对页面进行初始化，查询数据显示，也就是在mounted中进行一次查询操作

``` javascript
mounted() {
    this.getBooks()
  },
```
然后问题就来了，因为$ref是非响应式的，所以在页面初始化的时候，并没有被创建，也就无法通过验证，会报错

``` javascript
validate is undefined
```

#### 解决方法
将验证方法，拆出来，也就是调用ref的地方，不要放在钩子函数中，待页面加载完在进行调用验证。

``` javascript
 methods: {
    searchBooks() {
      this.$refs['booksForm'].validate(valid => {
        if (valid) {
          this.getBooks(this.booksData)
        }
      })
    },
```
由searchBooks进行一层包装，将调用ref的验证放到外面，在mounted的钩子函数中还是调用getBooks方法。




