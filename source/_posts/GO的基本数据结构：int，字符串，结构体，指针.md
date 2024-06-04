---
title: GO的基本数据结构：int，字符串，结构体，指针
date: 2020-12-22 17:06:22
tags: go
categories: GO
comments: true
description: 解析go语言，go的基本类型 int string struct point
---

## int类型

![1](1.png)

变量i属于类型int，在内存中用一个32位字长(word)表示

变量j由于做了精确的转换，属于int32类型。尽管i和j有着相同的内存布局，但是它们属于不同的类型

变量f属于float类型，Go语言当前使用32位浮点型值表示(float32)。它与int32很像，但是内部实现不同。

接下来，变量bytes的类型是[5]byte，一个由5个字节组成的数组。它的内存表示就是连起来的5个字节，就像C的数组。类似地，变量primes是4个int的数组。

## string类型

字符串在Go语言内存模型中用一个2字长的数据结构表示。它包含一个指向字符串存储数据的指针和一个长度数据

![2](2.png)

因为string类型是不可变的，对于多字符串共享同一个存储数据是安全的。切分操作str[i:j]会得到一个新的2字长结构，一个可能不同的但仍指向同一个字节序列(即上文说的存储数据)的指针和长度数据。

这意味着字符串切分可以在不涉及内存分配或复制操作。这使得字符串切分的效率等同于传递下标

### string的遍历

要么string打印，要么fmt格式化输出，得到字符串，不然得到的是byte类型

``` javascript
 	fmt.Println("方法一  格式化打印")
    for _, ch1 := range str {
        fmt.Printf("%q",ch1) //单引号围绕的字符字面值，由go语法安全的转义
    }
    fmt.Println("方法二  转化输出格式")
    for _, ch2 := range str {
        fmt.Println(string(ch2))
    }

```

### strings包常用操作

#### Count(s string, str string) int

计算字符串str在s中的非重叠个数。如果str为空串则返回s中的字符（非字节）个数+1。

#### Index(s string, str string) int 

返回子串str在字符串s中第一次出现的位置。如果找不到则返回-1；如果str为空，则返回0。

#### LastIndex(s string, str string) int

返回子串str在字符串s中最后一次出现的位置。如果找不到则返回-1；如果str为空则返回字符串s的长度。

#### IndexRune(s string, r rune) int

返回字符r在字符串s中第一次出现的位置。如果找不到则返回-1。

#### IndexAny(s string, str string) int 

返回字符串str中的任何一个字符在字符串s中第一次出现的位置。如果找不到或str为空则返回-1。

#### LastIndexAny(s string, str string) int

返回字符串str中的任何一个字符在字符串s中最后一次出现的位置。如果找不到或str为空则返回-1。

#### Contains(s string, str string) bool

判断字符串s中是否包含个子串str。包含或者str为空则返回true。

#### ContainsAny(s string, str string) bool

判断字符串s中是否包含个子串str中的任何一个字符。包含则返回true，如果str为空则返回false。

#### ContainsRune(s string, r rune) bool

判断字符串s中是否包含字符r。

#### SplitN(s, str string, n int) []string

以str为分隔符，将s切分成多个子串，结果中**不包含**str本身。如果str为空则将s切分成Unicode字符列表。如果s中没有str子串，则将整个s作为[]string的第一个元素返回。参数n表示最多切分出几个子串，超出的部分将不再切分，最后一个n包含了所有剩下的不切分。如果n为0，则返回nil；如果n小于0，则不限制切分个数，全部切分。

#### SplitAfterN(s, str string, n int) []string

以str为分隔符，将s切分成多个子串，结果中**包含**str本身。如果str为空，则将s切分成Unicode字符列表。如果s 中没有str子串，则将整个s作为 []string 的第一个元素返回。参数n表示最多切分出几个子串，超出的部分将不再切分。如果n为0，则返回 nil；如果 n 小于 0，则不限制切分个数，全部切分。

#### Split(s, str string) []string

以str为分隔符，将s切分成多个子切片，结果中**不包含**str本身。如果str为空，则将s切分成Unicode字符列表。如果s中没有str子串，则将整个s作为[]string的第一个元素返回。

#### SplitAfter(s, str string) []string

以str为分隔符，将s切分成多个子切片，结果中**包含**str本身。如果 str 为空，则将 s 切分成Unicode字符列表。如果s中没有str子串，则将整个s作为[]string的第一个元素返回。

#### Fields(s string) []string

以连续的空白字符为分隔符，将s切分成多个子串，结果中不包含空白字符本身。空白字符有：\t, \n, \v, \f, \r, ’ ‘, U+0085 (NEL), U+00A0 (NBSP) 。如果 s 中只包含空白字符，则返回一个空列表。

#### FieldsFunc(s string, f func(rune) bool) []string

以一个或多个满足f(rune)的字符为分隔符，将s切分成多个子串，结果中不包含分隔符本身。如果s中没有满足f(rune)的字符，则返回一个空列表。

#### Join(s []string, str string) string

将s中的子串连接成一个单独的字符串，子串之间用str分隔。

#### HasPrefix(s string, prefix string) bool

判断字符串s是否以prefix开头。

#### HasSuffix(s, suffix string) bool 

判断字符串s是否以prefix结尾。

#### Map(f func(rune) rune, s string) string

将s中满足f(rune)的字符替换为f(rune)的返回值。如果f(rune)返回负数，则相应的字符将被删除。

#### Repeat(s string, n int) string

将n个字符串s连接成一个新的字符串。

#### ToUpper(s string) string

将s中的所有字符修改为其大写格式。对于非ASCII字符，它的大写格式需要查表转换。

#### ToLower(s string) string

将s中的所有字符修改为其小写格式。对于非ASCII字符，它的小写格式需要查表转换。

#### ToTitle(s string) string

将s中的所有字符修改为其Title格式，大部分字符的Title格式就是Upper格式，只有少数字符的Title格式是特殊字符。这里的ToTitle主要给Title函数调用。

#### TrimLeftFunc(s string, f func(rune) bool) string

删除s头部连续的满足f(rune)的字符。

#### TrimRightFunc(s string, f func(rune) bool) string

删除s尾部连续的满足f(rune)的字符。

#### TrimFunc(s string, f func(rune) bool) string

删除s首尾连续的满足f(rune)的字符。

#### IndexFunc(s string, f func(rune) bool) int

返回s中第一个满足f(rune) 的字符的字节位置。如果没有满足 f(rune) 的字符，则返回 -1。

#### LastIndexFunc(s string, f func(rune) bool) int

返回s中最后一个满足f(rune)的字符的字节位置。如果没有满足 f(rune) 的字符，则返回 -1。

#### Trim(s string, str string) string

删除s首尾连续的包含在str中的字符。

#### TrimLeft(s string, str string) string

删除s头部连续的包含在str中的字符串。

#### TrimRight(s string, str string) string

删除s尾部连续的包含在str中的字符串。

#### TrimSpace(s string) string

删除s首尾连续的的空白字符。

#### TrimPrefix(s, prefix string) string

删除s头部的prefix字符串。如果s不是以prefix开头，则返回原始s。

#### TrimSuffix(s, suffix string) string

删除s尾部的suffix字符串。如果s不是以suffix结尾，则返回原始s。（只去掉一次，注意和TrimRight区别）

#### Replace(s, old, new string, n int) string

返回s的副本，并将副本中的old字符串替换为new字符串，替换次数为n次，如果n为-1，则全部替换；如果 old 为空，则在副本的每个字符之间都插入一个new。

#### EqualFold(s1, s2 string) bool

比较UTF-8编码在小写的条件下是否相等，不区分大小写，同时它还会对特殊字符进行转换。比如将“ϕ”转换为“Φ”、将“Ǆ”转换为“ǅ”等，然后再进行比较。
“==”比较字符串是否相等，区分大小写，返回bool。

#### Compare(s1 string, s2 string) int1

比较字符串，区分大小写，比”==”速度快。相等为0，不相等为-1。


## 结构体和指针

type Point struct { X, Y int }
![3](3.png)
Point{10,20}表示一个已初始化的Point类型。对它进行取地址表示一个指向刚刚分配和初始化的Point类型

结构体的域在内存中是紧挨着排列的。

出于效率的考虑，大型的结构体通常都使用结构体指针的方式，直接传递给函数，或者从函数中返回

1.当函数本意是修改原始数据，用指针传递
2.结构体很大，用指针传递
3.结构体很小，不打算修改内容，用值传递，值传递是传递实参的副本，对本身没有影响