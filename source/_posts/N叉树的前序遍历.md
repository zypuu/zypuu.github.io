---
title: N叉树的前序遍历
date: 2020-12-16 20:05:00
tags: 算法
categories: 数据算法
comments: true
description: 关于N叉树的前序遍历方法
---

### 递归

#### python

类似二叉树，子节点for循环遍历一下就好

``` javascript

# Definition for a Node.
# class Node:
#    def __init__(self, val=None, children=None):
#        self.val = val
#        self.children = children

class Solution:
    def preorder(self, root: 'Node') -> List[int]:
        res = []
        def handle(root):
            if not root:
                return
            res.append(root.val)
            for i in root.children:
                handle(i)
        handle(root)
        return res

```

### 迭代

按子节点顺序即可

#### python

``` javascript
class Solution(object):
    def preorder(self, root):
        if root is None:
            return []
        
        stack, output = [root, ], []            
        while stack:
        	# 移除最后一个元素
            root = stack.pop()
            output.append(root.val)
            # 反转数组 
            stack.extend(root.children[::-1])
                
        return output

```

时间复杂度：时间复杂度：O(M)，其中 MM 是 N 叉树中的节点个数。每个节点只会入栈和出栈各一次。

空间复杂度：O(M)。在最坏的情况下，这棵 N 叉树只有 2 层，所有第 2 层的节点都是根节点的孩子。将根节点推出栈后，需要将这些节点都放入栈，共有 M−1 个节点，因此栈的大小为 O(M)
