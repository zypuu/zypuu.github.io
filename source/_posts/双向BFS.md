---
title: 双向BFS
date: 2021-03-26 16:00:00
tags: 算法
categories: 数据算法
comments: true
description: 双向BFS与单向bfs
---

### DFS模板
``` javascript
// 深度优先，栈遍历
func dfs(root *TreeNode) {
	// root不存在则返回
	if root == nil {
		return
	}
	var dfs func()
	dfs = func() {
		if visit[root] {
			return
		}
		visit[root] = true
		for i := range root.Children {
			if !visit[i] {
				dfs(i)
			}
			
		}
	}
	
}

```

### BFS模板
``` javascript
// 广度优先，队列遍历
func bfs(root *TreeNode) {
	// root不存在则返回
	if root == nil {
		return
	}
	// 手动维护一个队列，初始化，并放入root，还有一个visited的map
	q := []*TreeNode{root}
	visited := map[*TreeNode]bool{}
 	// 未访问则记录,处理当前层
 	for len(q) > 0 {
 		// 节点出队
 		node := q[0]
 		q = q[1:]
 		// 访问记录
 		visited[node] = true
 		// 处理逻辑
 		process(node)
 		// 更新q，更新node
 		nodes = related(node)
 		q = append(q, nodes...)
 	}
	
}

```

### 双向BFS模板

``` javascript
// 双向bfs
func tebfs(root *TreeNode) {
	// 开始队列
	startQ := []interface{}
	// 结束队列
	endQ := []interface{}
	// 开始使用过的记录
	visitedStart := map[int]bool
	// 结束使用记录
	visitedEnd := map[int]bool
	// 全局使用记录
	visited := map[int]bool
	
	// 遍历
	for len(startQ) > 0 {
		// 遍历开始队列
		qLen := len(startQ)
		for i := 0; i < qLen; i++ {
			cur := q[0]
			q = q[1:]
			// 处理逻辑
			process()
			// 开始记录处理
			visitedStart()
			// 放入队列
			startQ = append(startQ, ...)
		}
		// 层遍历完处理逻辑,互换队列，互换记录map
		if len(startQ) > len(endQ) {
			startQ, endQ = endQ, startQ
			visitedStart, visitedEnd = visitedEnd, visitedStart
		}
	}
}
```
### A* 模板
``` javascript
func ASearch() {
	// 初始化优先队列
	pq = priorityQ()

	pq =append(pq, start) // 获取优先队列

	visited := map[int]bool{start : true}
	for len(pq) > 0 {
		node := pq.get() // 根据优先级获取
		visited[node] = true

		process()
		// 添加进队列
		pq = append(node.next)
	} 	
}
```

### 例题

#### 单词接龙

``` javascript
// ladderLength 
// 单向bfs
func ladderLength(beginWord string, endWord string, wordList []string) int {
    vis := make(map[string]bool, len(wordList))
    for i := 0; i < len(wordList); i++ {
        vis[wordList[i]] = true
    }
    // 初始化队列
    q := []string{beginWord}
    // count是for之后++
    count := 1
    for len(q) > 0 {
    	// 记录当前队列长度，遍历当前队列，q长度会变
        qLen := len(q)
        for k := 0; k < qLen; k++ {
        	// 出队
            cur := q[0]
            q = q[1:]
            if cur == endWord {
                return count
            }
            for i := 0; i < len(cur); i++ {
                for j := 'a'; j <= 'z'; j++ {
                	// 得到新单词
                    newWord := cur[:i] + string(j) + cur[i+1:]
                    // 在map里
                    if vis[newWord] {
                        q = append(q, newWord)
                        vis[newWord] = false
                    }
                }
            }
        }
        count++ 
    }
    return 0
}

// 双向bfs
func ladderLength(beginWord string, endWord string, wordList []string) int {
	// 初始化startq， endq
    startQ := []string{beginWord}
    endQ := []string{endWord}
    // 初始化从前从后的两个map，记录是否使用过
    visStart := make(map[string]bool, len(wordList))
    visEnd := make(map[string]bool, len(wordList))
    // end是最终结果
    visEnd[endWord] = true
    // 单词map，用于判断是不是在库里
    vis := make(map[string]bool, len(wordList))
    for _, v := range wordList {
        vis[v] = true
    }
    // 如果结尾不在库里，返回0
    if _, ok := vis[endWord]; !ok {
        return 0
    }
    // count是for之后++
    count := 1
    // 遍历队列
    for len(startQ) > 0 {
        qLen := len(startQ)
        for i := 0; i < qLen; i++ {
        	// 出队
            cur := startQ[0]
            startQ = startQ[1:]
            // 拼新单词
            for c := 0; c < len(cur); c++ {
                for j := 'a'; j <= 'z'; j++ {
                    new := cur[:c] + string(j) + cur[c+1:]
                    // 如果不在库里，或者起始的记录过则跳过
                    if !vis[new] || visStart[new] {
                        continue
                    }
                    // 如果在结束的map里，这说明匹配到了
                    if visEnd[new] {
                        return count + 1
                    }
                    // 加入队列，记录start
                    startQ = append(startQ, new)
                    visStart[new] = true
                }
            }
        }
        // 层级遍历完++
        count++
        // 互换队列，保证每次遍历的队列长度最小，互换记录
        // 每次遍历都是 startq
        if len(startQ) > len(endQ) {
            startQ, endQ = endQ, startQ
            visStart, visEnd = visEnd, visStart
        }

    }
    return 0
}

```

#### 最小基因变化

``` javascript
// minMutation ...
// 单向bfs
func minMutation(start string, end string, bank []string) int {
    vis := make(map[string]bool, len(bank))
    // 判断是否重复，避免死循环
    for i := 0; i < len(bank); i++ {
        vis[bank[i]] = true
    }
    q := []string{start}
    item := []string{"A", "C", "G", "T"}
    // 这是转换次数，单词接龙是单词数目，注意
    res := 0
    for len(q) > 0 {
        qLen := len(q)
        for i := 0; i < qLen; i++ {
        	// 出队
            cur := q[0]
            q = q[1:]
            // 找到结果
            if cur == end {
                return res
            }
            // 循环每个字符
            for i := 0; i < len(cur); i++ {
                for j := 0; j < 4; j++ {
                    new := cur[:i] + item[j] + cur[i+1:]
                    if vis[new] {
                        q = append(q, new)
                        vis[new] = false
                    }
                }
            }
        }
        // 遍历完一层，结果++
        res++
    }
    return -1
}

// 双向bfs
func minMutation(start string, end string, bank []string) int {
	// 初始化
	startQ := []string{start}
    endQ := []string{end}

    visStart := make(map[string]bool, len(bank))
    visEnd := make(map[string]bool, len(bank))
    visEnd[end] = true

    // 判断end在不在库，初始化库
    vis := make(map[string]bool, len(bank))
    for _, v := range bank {
        vis[v] = true
    }
    if _, ok := vis[end];!ok {
        return -1
    }
    // 可更改字符
    item := []string{"A", "C", "G", "T"}
    res := 0
    for len(startQ) > 0 {
        qLen := len(startQ)
        for i := 0; i < qLen; i++ {
            cur := startQ[0]
            startQ = startQ[1:]
            for c := 0; c < len(cur); c++ {
                for _, v := range item {
                    new := cur[:c] + v + cur[c+1:]
                    // 不在库里，或者已使用过则跳过
                    if !vis[new] || visStart[new] {
                        continue
                    }
                    // 在结束里，返回结果+1
                    if visEnd[new] {
                        return res + 1
                    }
                    startQ = append(startQ, new)
                    visStart[new] = true
                }
            }
        }
        res++
        // 互换队列
        if len(startQ) > len(endQ) {
            startQ, endQ = endQ, startQ
            visStart, visEnd = visEnd, visStart
        }
    }
    return -1
}

```

#### 数独问题

``` javascript
// isValidSudoku
// 遍历通过map判断字符是否已经使用过
// 外层i，里层j， ij顺序代表一行一行遍历， ji顺序代表一列一列遍历
// 分块 行(i%3)*3 + j%3 列(i/3)*3 + j/3，得到的是一块9个的索引
func isValidSudoku(board [][]byte) bool {
    for i := 0; i < 9; i++ {
        visr := make(map[byte]bool, 9)
        visc := make(map[byte]bool, 9)
        visb := make(map[byte]bool, 9)
        for j := 0; j < 9; j++ {
            // 行 ij
            if board[i][j] != '.' {
                if visr[board[i][j]] { return false }
                visr[board[i][j]] = true
            }
            // 列 ji
            if board[j][i] != '.' {
                if visc[board[j][i]] { return false }
                visc[board[j][i]] = true
            }
            // 分块
            row := (i%3)*3 + j%3
            col := (i/3)*3 + j/3
            if board[row][col] != '.' {
                if visb[board[row][col]] { return false }
                visb[board[row][col]] = true
            }
        }
    }
    return true
}


// solveSudoku
// 递归回溯
func solveSudoku(board [][]byte)  {
	// 初始化，通过每一行的索引数字判断（每一列同理）
    var visr, visc [9][9]bool
    // 初始化块的，块的索引，以及里面的数字的索引判断
    var visb [3][3][9]bool
    // 初始化需要填入的点
    var spaces [][2]int
    // 预处理数据
    for i := 0; i < 9; i++ {
        for j := 0; j < 9; j++ {
        	// 需要填入的点加入列表
            if board[i][j] == '.' {
                spaces = append(spaces, [2]int{i, j})
            // 不需要填入的点，根据位置设置true
            } else {
            	// byte转int，-1
                b := board[i][j] - '1'
                visr[i][b] = true
                visc[j][b] = true
                visb[i/3][j/3][b] = true
            }
        }
    }
    // 递归函数
    var dfs func(n int) bool
    dfs= func(n int) bool {
    	// 遍历到最后一个点结束后，终止
        if n == len(spaces) {
            return true
        }
        // 取要填入的点
        i, j := spaces[n][0], spaces[n][1]
        for k := byte(0); k < 9; k++ {
        	// 判断是否已经使用过，有则跳过
            if visr[i][k] || visc[j][k] || visb[i/3][j/3][k] {
                continue
            }
            // 没有记录
            board[i][j] = k + '1'
            visr[i][k] = true
            visc[j][k] = true
            visb[i/3][j/3][k] = true
            // 递归下一个点，如果下一个点返回true，则返回true
            if dfs(n + 1) {
                return true
            }
            // 回溯
            board[i][j] = '.'
            visr[i][k] = false
            visc[j][k] = false
            visb[i/3][j/3][k] = false
        }
        // 最终如果都不返回true，则返回false，失败
        return false
    }
    dfs(0)
}
```


#### 扫雷游戏

``` javascript
// 深度优先，递归
func updateBoard(board [][]byte, click []int) [][]byte {
    // 8个方向的使用
    var dirX = []int{0, 1, 0, -1, 1, 1, -1, -1}
    var dirY = []int{1, 0, -1, 0, 1, -1, 1, -1}

    // 如果点击的是M，则是游戏结束，更新值
    if board[click[0]][click[1]] == 'M' {
        board[click[0]][click[1]] = 'X'
        return board
    }
    // 参数是坐标值，和每次递归更新后的board
    var dfs func([][]byte, int, int)
    dfs = func(board [][]byte, x, y int) {
        // 记录周围的M数量
        mCount := 0
        for i := 0; i < 8; i++ {
            tx := x + dirX[i]
            ty := y + dirY[i]
            // 边界条件
            if tx < 0 || ty < 0 || tx >= len(board) || ty >= len(board[0]) { continue }
            // 如果周围有M，则数字+1
            if board[tx][ty] == 'M' {
                mCount++
            }
        }
        // 周围有M，则更新为byte数字
        if mCount > 0 {
            board[x][y] = byte(mCount + '0')
        } else {
            // 周围没有M则更新为B
            board[x][y] = 'B'
            // 向8个方向扩展
            for i := 0; i < 8; i++ {
                tx := x + dirX[i]
                ty := y + dirY[i]
                // 如果周边的不是E，说明已经被访问过了，则跳过
                if tx < 0 || ty < 0 || tx >= len(board) || ty >= len(board[0]) || board[tx][ty] != 'E' { continue }
                dfs(board, tx, ty)
            }
        }        
    }
    dfs(board, click[0], click[1])
    return board
}


// 广度优先，bfs
func updateBoard(board [][]byte, click []int) [][]byte {
    // 8个方向
    var dirX = []int{0, 1, 0, -1, 1, 1, -1, -1}
    var dirY = []int{1, 0, -1, 0, 1, -1, 1, -1}

    // 点击到M结束
    if board[click[0]][click[1]] == 'M' {
        board[click[0]][click[1]] = 'X'
        return board
    }
    var bfs func([][]byte, int, int)
    bfs = func(board [][]byte, x, y int) {
        q := [][]int{}
        vis := make([][]bool, len(board))
        // 初始化所有的节点，是否被访问过
        for i := 0; i < len(vis); i++ {
            vis[i] = make([]bool, len(board[0]))
        }
        // 当前点击加入队列
        q = append(q, []int{x, y})
        // 记录当前点击访问
        vis[x][y] = true
        // 遍历队列
        for i := 0; i < len(q); i++ {
            // 获取当前坐标，初始化周围M的数量
            mCount, cx, cy := 0, q[i][0], q[i][1]
            // 找周围的M
            for i := 0; i < 8; i++ {
                tx, ty := cx + dirX[i], cy + dirY[i]
                if tx < 0 || tx >= len(board) || ty < 0 || ty >= len(board[0]) {
                    continue
                }
                // 记录周围的M
                if board[tx][ty] == 'M' {
                    mCount++
                }
            }
            // 如果有M，更新值
            if mCount > 0 {
                board[cx][cy] = byte(mCount + '0')
            } else {
                // 没有M更新为B
                board[cx][cy] = 'B'
                // 将周围的加入队列
                for i := 0; i < 8; i++ {
                    tx, ty := cx + dirX[i], cy + dirY[i]
                    // 这里不需要在存在 B 的时候继续扩展，因为 B 之前被点击的时候已经被扩展过了
                    if tx < 0 || tx >= len(board) || ty < 0 || ty >= len(board[0]) || board[tx][ty] != 'E' || vis[tx][ty] {
                        continue
                    }
                    q = append(q, []int{tx, ty})
                    vis[tx][ty] = true
                }
            }
    }
    }
    bfs(board, click[0], click[1])
    

    return board
}
```