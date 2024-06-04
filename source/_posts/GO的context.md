---
title: GO的context
date: 2021-01-21 17:12:00
tags: go
categories: GO
comments: true
description: 解析go语言，go的context
---

## 场景问题

通过done channel 可以用于协程间通信，由主协程告知子协程取消，结束，终止任务等

假如主协程中有多个任务1, 2, …m，主协程对这些任务有超时控制；而其中任务1又有多个子任务1, 2, …n，任务1对这些子任务也有自己的超时控制，那么这些子任务既要感知主协程的取消信号，也需要感知任务1的取消信号

如果还是使用done channel的用法，我们需要定义两个done channel，子任务们需要同时监听这两个done channel。如果层级更深，如果这些子任务还有子任务，那么使用done channel的方式将会变得非常繁琐且混乱

通过context，可以实现：

1.上层任务取消后，所有的下层任务都会被取消；

2.中间某一层的任务取消后，只会将当前任务的下层任务取消，而不会影响上层的任务以及同级任务

## context实现

context是Go并发编程中常用到一种编程模式， 使用context可以使开发者方便的在这些goroutine里传递request相关的数据、取消goroutine的signal或截止日期

### context接口

context包含4个接口方法

``` javascript
type Context interface {

    Deadline() (deadline time.Time, ok bool)

    Done() <-chan struct{}

    Err() error

    Value(key interface{}) interface{}
}
```
Deadline：返回绑定当前context的任务被取消的截止时间；如果没有设定期限，将返回ok == false

Done：当绑定当前context的任务被取消时，将返回一个关闭的channel；如果当前context不会被取消，将返回nil

当一个父operation启动一个goroutine用于子operation，这些子operation不能够取消父operation。下面描述的WithCancel函数提供一种方式可以取消新创建的Context.

Context可以安全的被多个goroutine使用。开发者可以把一个Context传递给任意多个goroutine然后cancel这个context的时候就能够通知到所有的goroutine

Err：如果Done返回的channel没有关闭，将返回nil;如果Done返回的channel已经关闭，将返回非空的值表示任务结束的原因。如果是context被取消，Err将返回Canceled；如果是context超时，Err将返回DeadlineExceeded

Value： 返回context存储的键值对中当前key对应的值，如果没有对应的key,则返回nil

### emptyCtx

``` javascript
// An emptyCtx is never canceled, has no values, and has no deadline. It is not
// struct{}, since vars of this type must have distinct addresses.
type emptyCtx int

func (*emptyCtx) Deadline() (deadline time.Time, ok bool) {
    return
}

func (*emptyCtx) Done() <-chan struct{} {
    return nil
}

func (*emptyCtx) Err() error {
    return nil
}

func (*emptyCtx) Value(key interface{}) interface{} {
    return nil
}

func (e *emptyCtx) String() string {
    switch e {
    case background:
        return "context.Background"
    case todo:
        return "context.TODO"
    }
    return "unknown empty Context"
}

var (
    background = new(emptyCtx)
    todo       = new(emptyCtx)
)

func Background() Context {
    return background
}

func TODO() Context {
    return todo
}
```

一般不会直接使用emptyCtx，emptyCtx没有任何功能，常用作顶层的context

通过Background和todo拿到两个emptyCtx实例：

Background：通常被用于主函数、初始化以及测试中，作为一个顶层的context，也就是说一般我们创建的context都是基于Background

TODO：是在不确定使用什么context的时候才会使用

### valueCtx

``` javascript
type valueCtx struct {
	Context   // 继承父节点conntext
	key, val interface{} // 携带键值对
}

func WithValue(parent Context, key, val interface{}) Context {
	if key == nil {
		panic("nil key")
	}
	if !reflectlite.TypeOf(key).Comparable() {
		panic("key is not comparable")
	}
	return &valueCtx{parent, key, val}
}

func (c *valueCtx) Value(key interface{}) interface{} {
	if c.key == key {
		return c.val
	}
	return c.Context.Value(key)
}
```

0.有一个context变量作为父节点

1.用一个context变量，继承父节点的context的所有信息，并且携带kv结构，可以携带额外信息

2.valueCtx实现了Value方法，用以在context链路上获取key对应的值，如果当前context上不存在需要的key,会沿着context链向上寻找key对应的值，直到根节点， 获取value的过程就是在这条context链上由尾部上前搜寻

3.WithValue用以向context添加键值对

4.添加键值对不是在原context结构体上直接添加，而是以此context作为父节点，重新创建一个新的valueCtx子节点，将键值对添加在子节点上，由此形成一条context链

### cancelCtx

``` javascript
type cancelCtx struct {
    Context

    mu       sync.Mutex            // protects following fields
    done     chan struct{}         // created lazily, closed by first cancel call
    children map[canceler]struct{} // set to nil by the first cancel call
    err      error                 // set to non-nil by the first cancel call
}

type canceler interface {
    cancel(removeFromParent bool, err error)
    Done() <-chan struct{}
}
```
1.cancelCtx中也有一个context变量作为父节点

2.done表示一个channel，用来表示传递关闭信号

3.children是个map，存储子节点

4.err用于存储错误信息表示任务结束的原因

#### cancel方法

``` javascript
func (c *cancelCtx) Done() <-chan struct{} {
    c.mu.Lock()
    if c.done == nil {
        c.done = make(chan struct{})
    }
    d := c.done
    c.mu.Unlock()
    return d
}

func (c *cancelCtx) Err() error {
    c.mu.Lock()
    err := c.err
    c.mu.Unlock()
    return err
}

func (c *cancelCtx) cancel(removeFromParent bool, err error) {
    if err == nil {
        panic("context: internal error: missing cancel error")
    }
    c.mu.Lock()
    if c.err != nil {
        c.mu.Unlock()
        return // already canceled
    }
    // 设置取消原因
    c.err = err
    设置一个关闭的channel或者将done channel关闭，用以发送关闭信号
    if c.done == nil {
        c.done = closedchan
    } else {
        close(c.done)
    }
    // 将子节点context依次取消
    for child := range c.children {
        // NOTE: acquiring the child's lock while holding parent's lock.
        child.cancel(false, err)
    }
    c.children = nil // 后续就不用removeFromParent了
    c.mu.Unlock()

    if removeFromParent {
        // 将当前context节点从父节点上移除
        removeChild(c.Context, c)
    }
}
```
cancel 有两个参数，一个是 removeFromParent，表示当前的取消操作是否需要把自己从父 Context 中移除，第二个参数就是执行取消操作需要返回的错误提示

1.如果 c.done 是 nil (父 Context 是 emptyCtx 的情况)，就赋值 closedchan，  closedchan 是一个被关闭的channel

2.如果不是nil，就直接关闭。然后递归关闭子 Context。

3.关闭子 Context 的时候，removeFromParent 参数传值是 false，这是因为当前 Context 在关闭的时候，把 child 置成了 nil，所以子 Context 就不用再执行一次从父 Context 移除自身的操作了

#### WithCancel

WithCancel函数用来创建一个可取消的context，即cancelCtx类型的context。WithCancel返回一个context和一个CancelFunc，调用CancelFunc即可触发cancel操作

``` javascript
type CancelFunc func()

func WithCancel(parent Context) (ctx Context, cancel CancelFunc) {
    c := newCancelCtx(parent)
    propagateCancel(parent, &c)
    return &c, func() { c.cancel(true, Canceled) }
}

// newCancelCtx returns an initialized cancelCtx.
func newCancelCtx(parent Context) cancelCtx {
    // 将parent作为父节点context生成一个新的子节点
    return cancelCtx{Context: parent}
}

func propagateCancel(parent Context, child canceler) {
    if parent.Done() == nil {
        // parent.Done()返回nil表明父节点以上的路径上没有可取消的context
        return // parent is never canceled
    }
    // 获取最近的类型为cancelCtx的祖先节点
    if p, ok := parentCancelCtx(parent); ok {
        p.mu.Lock()
        if p.err != nil {
            // parent has already been canceled
            child.cancel(false, p.err)
        } else {
            if p.children == nil {
                p.children = make(map[canceler]struct{})
            }
            // 将当前子节点加入最近cancelCtx祖先节点的children中
            p.children[child] = struct{}{}
        }
        p.mu.Unlock()
    } else {
        go func() {
            select {
            case <-parent.Done():
                child.cancel(false, parent.Err())
            case <-child.Done():
            }
        }()
    }
}

func parentCancelCtx(parent Context) (*cancelCtx, bool) {
    for {
        switch c := parent.(type) {
        case *cancelCtx:
            return c, true
        case *timerCtx:
            return &c.cancelCtx, true
        case *valueCtx:
            parent = c.Context
        default:
            return nil, false
        }
    }
}
```

cancelCtx取消时，会将后代节点中所有的cancelCtx都取消

propagateCancel即用来建立当前节点与祖先节点这个取消关联逻辑

流程：

1.判断parent.Done() == nil，表明父节点以上的路径上没有可取消的context，不需要处理

2.如果在context链上找到到cancelCtx类型的祖先节点，则判断这个祖先节点是否已经取消，如果已经取消就取消当前节点；否则将当前节点加入到祖先节点的children列表

3.否则开启一个协程，监听parent.Done()和child.Done()，一旦parent.Done()返回的channel关闭，即context链中某个祖先节点context被取消，则将当前context也取消

### timerCtx

timerCtx是一种基于cancelCtx的context类型，可以定时取消

``` javascript
type timerCtx struct {
    cancelCtx
    timer *time.Timer // Under cancelCtx.mu.

    deadline time.Time
}

func (c *timerCtx) Deadline() (deadline time.Time, ok bool) {
    return c.deadline, true
}

func (c *timerCtx) cancel(removeFromParent bool, err error) {
    将内部的cancelCtx取消
    c.cancelCtx.cancel(false, err)
    if removeFromParent {
        // Remove this timerCtx from its parent cancelCtx's children.
        removeChild(c.cancelCtx.Context, c)
    }
    c.mu.Lock()
    if c.timer != nil {
        取消计时器
        c.timer.Stop()
        c.timer = nil
    }
    c.mu.Unlock()
}
```

内部使用 cancelCtx实现取消，定时器timer，和过期时间deadline实现定时取消功能

timerCtx取消时，也就是调用cancel方法，如上面注释所示
1.先将内部的cancelCtx取消，调用cancelCtx的cancel方法，

2.如果需要则将自己从cancelCtx祖先节点上移除

3.取消计时器

#### WithDeadline

通过该方法，可以返回一个基于parent的可取消的context，过期时间设置为d

``` javascript
func WithDeadline(parent Context, d time.Time) (Context, CancelFunc) {
    if cur, ok := parent.Deadline(); ok && cur.Before(d) {
        // The current deadline is already sooner than the new one.
        return WithCancel(parent)
    }
    c := &timerCtx{
        cancelCtx: newCancelCtx(parent),
        deadline:  d,
    }
    // 建立新建context与可取消context祖先节点的取消关联关系
    propagateCancel(parent, c)
    dur := time.Until(d)
    if dur <= 0 {
        c.cancel(true, DeadlineExceeded) // deadline has already passed
        return c, func() { c.cancel(false, Canceled) }
    }
    c.mu.Lock()
    defer c.mu.Unlock()
    if c.err == nil {
        c.timer = time.AfterFunc(dur, func() {
            c.cancel(true, DeadlineExceeded)
        })
    }
    return c, func() { c.cancel(true, Canceled) }
}
```

1.如果父节点parent有过期时间并且过期时间早于d，那么新建的子节点context无需设置过期时间，使用WithCancel创建一个可取消的context

2.不满足以上条件，用parent和过期时间d创建一个定时取消的timerCtx，并建立新建context与可取消context祖先节点的取消关联关系

3.判断当前时间距离过期时间d的时长dur

4.dur小于0，即当前已经过了过期时间，则直接取消新建的timerCtx，原因为DeadlineExceeded

5.为新建的timerCtx设置定时器，一旦到达过期时间即取消当前timerCtx

#### WithTimeout
该方法最终也是withDeadline，只不过接收的不是一个时间点，而是一个时间时长timeout
``` javascript
func WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc) {
    return WithDeadline(parent, time.Now().Add(timeout))
}
```

## 使用场景