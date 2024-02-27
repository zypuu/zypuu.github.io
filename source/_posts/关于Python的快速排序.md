---
title: 关于Python的快速排序
date: 2018-06-26 19:54:41
tags: 算法
categories: 数据算法
comments: true
description: python实现快速排序，Quick sort
---
## 原理
快速排序基本思想是：通过一趟排序将要排序的数据分割成独立的两部分，其中一部分的所有数据都比另外一部分的所有数据都要小，然后再按此方法对这两部分数据分别进行快速排序，整个排序过程可以递归进行，以此达到整个数据变成有序序列。

比如有一个数组：

6 2 4 5 3

第一步：选取一个基准数，不要被这个名词吓到了，你可以把它看作是一个比较大小的数，因为排序就是比较大小，

比如我选取最后一个数3为基准数，依次把数组的数和3比较，比3小的放左边，比3大的放右边，这样有如下结果：

2 3 6 4 5

第二步：判断区间个数，经过第一步后左边区间只有一个数了，没有数字再和它比较了，因此不需要重复操作，右边区间还有：

6 4 5

重复第一步，选取5作为基准数，得到比较结果：

4 5 6

这样左右两边区间都只有一个数了，这就标志着排序完成，最后把所有区间合并就得到排序结果：

2 3 4 5 6

## 代码实现

``` javascript
def quick_sort(array):
  less = []; greater = []
  if len(array) <= 1:
    return array
  pivot = array.pop()
  for x in array:
    if x <= pivot: less.append(x)
    else: greater.append(x)
  return quick_sort(less) + [pivot] + quick_sort(greater)
 
```

