---
title: 关于vue前端的生命周期与钩子函数
date: 2020-05-03 11:19:28
tags: Vue
categories: 前端
comments: true
description: 前端页面的一问题处理
---

#### beforeCreate
Vue对象用新方法实例化。它创建一个Vue类的对象来处理DOM元素。对象的这个生命阶段可以通过beforeCreated 挂钩来访问 。我们可以在这个钩子中插入我们的代码，在对象初始化之前执行。

#### created

在这个生命阶段，对象及其事件完全初始化。 created 是访问这个阶段并编写代码的钩子。

#### beforeMount

这个钩子被调用 beforeMounted。在这个阶段，它检查是否有任何模板可用于要在DOM中呈现的对象。如果没有找到模板，那么它将所定义元素的外部HTML视为模板。

#### mounted

一旦模板准备就绪。它将数据放入模板并创建可呈现元素。用这个新的数据填充元素替换DOM元素。这一切都发生在mounted钩子上。

#### beforeUpdate

在外部事件/用户输入beforeUpdate发生更改时，此钩子即 在反映原始DOM元素的更改之前被触发。

为了解决这个问题 beforeUpdated，我添加了下面的代码。它通过更新DOM来更改运行时中的hello_message。

#### updated

然后，通过实际更新DOM对象并触发updated，屏幕上的变化得到呈现 。

#### beforeDestroy

#### destroyed

vue实例在被创建的时候会经历这些钩子函数
1. 在beforeCreate和created钩子函数之间的生命周期
在这个生命周期之间，进行初始化事件，进行数据的观测，可以看到在created的时候数据已经和data属性进行绑定（放在data中的属性当值发生改变的同时，视图也会改变）。created的时候，数据已经和data进行绑定了
注意看下：此时还是没有el选项，也就是beforecreate的时候，数据还没有和data绑定。
2. created钩子函数和beforeMount间的生命周期
首先会判断对象是否有el选项。如果有的话就继续向下编译，如果没有el选项，则停止编译，也就意味着停止了生命周期，直到在该vue实例上调用vm.$mount(el)。