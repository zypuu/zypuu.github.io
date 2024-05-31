---
title: GO的基本数据结构：channel
date: 2021-01-14 17:09:00
tags: GO
categories: GO
comments: true
description: 解析go语言，go的基本数据结构 channel
---

## channel实现

channel可以被存储到变量中，可以作为参数传递给函数，也可以作为函数的返回值返回。

作为Go语言的核心特征之一，虽然channel看上去很高端，但是其实channel仅仅就是一个数据结构

线程间有竞争条件，那么对共享数据的访问往往需要加锁来保证一致性，而针对不同的访问竞争，比如读/读、读/写、写/写，需要用不同的锁机制

Go语言采用的并发模型是`CSP（Communicating Sequential Processes）`，提倡**通过通信共享内存**而不是**通过共享内存而实现通信**

### channel状态

初始化channel

``` javascript
var ch = chan string // A channel is in a nil state when it is declared to its zero value
ch = nil // A channel can be placed in a nil state
 
/* open channel */
ch := make(chan string) // A channel is in a open state when it’s made using the built-in function make.
 
/* closed channel */
close(ch) 
```

channel分为三种状态：

1.nil： 不允许读写，blocked状态，会阻塞

2.open： 允许读写， allowed状态

3.closed： 写会panic，可以读

在channel被close之后，goruntine仍然可以从channel取走数据，如果channel中没有数据可取时，receive操作会立刻返回nil

range循环可以直接在channel上迭代，当channel被关闭并且没有数据时可以直接跳出循环。

另外，对于nil和closed状态的channel执行close操作也会触发panic异常

### 缓冲channel与非缓冲channel

channel的读写操作可以不传递数据

场景：

一个goroutine可以同时给多个goroutine发送消息，只是这个消息不携带额外的数据，所以常被用于批量goruntine的退出

goroutine A对channel执行了close操作，而goruntine B得到channel已经被关闭这个信息后可以执行相应的处理

``` javascript
ch := make(chan struct{})
// 写入ch 
ch <- struct{}{}
// 读取ch
<- ch
```

也可以传递数据：

goroutine A执行send发送数据，而goroutine B执行receive接收数据。channel携带的数据只能被一个goruntine得到，一个goruntine取走数据后这份数据在channel里就不复存在了

携带数据的可以分为缓冲和非缓冲

#### 非缓冲channel

不存储数据，只传递数据

goroutine A在往channel发送数据完成之前，一定有goroutine B在等着从这个channel接收数据，否则发送就会导致发送的goruntine被block住，所以发送和接收的goruntine是耦合的

所以会有两个goroutine

死锁场景：

ch发送数据时就使main gouruntine被永久block住，导致程序死锁，因为没有goroutine等待接收数据，main还没执行完，会导致ch阻塞锁住
如果channel长度是1，则不会发生死锁
``` javascript
func main() {
	var ch = make(chan string)
	ch <- "hello" //fatal error: all goroutines are asleep - deadlock! goroutine 1 [chan send]:
	fmt.Println(<-ch)
}

```
下面这种也会死锁，ch里没有数据，直接读也会锁住
``` javascript
func main() {
	var ch = make(chan string)
	fmt.Println(<-ch) //fatal error: all goroutines are asleep - deadlock! goroutine 1 [chan receive]:
	ch <- "hello"
}
```
单起一个goroutine就可以正常工作
``` javascript
func main() {
	var ch = make(chan string)
	go func() {
		fmt.Println(<-ch) //out: hello
	}()
	ch <- "hello"
}
```

退出场景：
main goroutine会在go func执行前就退出了，无法打印1-10
``` javascript
func main() {
	go func() {
		for i := 0; i < 10; i++ {
			fmt.Printf("%d ", i)
		}
	}()
	fmt.Println("hello")
}
```

让两个goruntine之间有一些通信，让main goruntine收到sub goruntine通知后再退出。在这种场景中，channel并不携带任何数据，只是起到一个信号的作用

``` javascript
func main() {
	var ch = make(chan string)
	go func() {
		for i := 0; i < 10; i++ {
			fmt.Printf("%d ", i)
		}
		ch <- "exit"
	}()
	fmt.Println("hello")
	<-ch
}
```

#### 缓冲channel

``` javascript
func main() {
	var ch = make(chan string, 1)
	ch <- "hello" //fatal error: all goroutines are asleep - deadlock! goroutine 1 [chan send]:
	fmt.Println(<-ch)
}
```
以上场景，如果没有指定channel长度为1，则会发生死锁
同一个goroutine内，读，放到写前面会导致死锁
对比上面非缓冲channel

注意：长度不同，会有区别

对于长度为1的channel
第二个数据发送完成之前，之前发送的第一个数据一定被取走了，否则发送也会被block住，这其实说明了数据的交付得到了延迟保证

对于长度大于1的channel
发送数据时，之前发送的数据不能保证一定被取走了，并且buffer size越大，数据的交付得到的保证越少。也正是由于这种无保证交付，减少了goroutine之间通信时的阻塞延迟，根据发送数据、接收数据、数据处理的速度合理的设计buffer size，甚至可以在不浪费空间的情况下做到没有任何延迟

如果channel buffer已经塞满了数据，继续执行发送会导致当前goruntine被block住（阻塞），直到channel中的数据被取走一部分才可以继续向channel发送数据

PS：

1.channel主要用于多个goroutine之间通信，不要在单个goruotine中进行读写，容易导致死锁

2.合理设计goroutine数量，和channel的size

### goroutine泄露

``` javascript
func main() {
	ch := make(chan string)
	count := 3
	for index := 0; index < count; index++ {
		go func() {
			time.Sleep(time.Duration(rand.Intn(200)) * time.Millisecond)
			ch <- "hello"
		}()
	}
	fmt.Println(<-ch)
	time.Sleep(time.Duration(rand.Intn(5000)) * time.Millisecond)
	//other work
}
```
上面这个例子，3个goroutine发送数据，1个接收数据

所以只有最早执行完send的goruntine的数据能得到交付，另外两个慢一点的goruntine将会被永远block住直到整个程序退出。这种情况也是一个BUG，称为goruntine泄露，泄露的goruntine并不会被自动回收

确保每个不再需要的goruntine正常退出非常重要，尤其是常驻内存的后台程序。

最需要注意的场景就是负责接收的goruntine在永久退出（return）接收处理时，要确保发送的goruntine不会因为继续发送数据被block住

改进：
``` javascript
func main() {
	ch := make(chan string)
	count := 3
	for index := 0; index < count; index++ {
		go func() {
			time.Sleep(time.Duration(rand.Intn(200)) * time.Millisecond)
			ch <- "hello"
		}()
	}
	for index := 0; index < count; index++ {
		fmt.Println(<-ch)
	}
	time.Sleep(time.Duration(rand.Intn(5000)) * time.Millisecond)
	//other work
}
```

### cap和len

cap可获取channel的长度容量

len可获取channel的数据个数

### range

range可以对channel进行迭代，不断接收channel里的数据（没有数据时阻塞），直到channel被关闭后自动退出迭代
``` javascript
func main() {
	var ch = make(chan string, 2)
	go func() {
		for i := 0; i < 5; i++ {
			time.Sleep(500 * time.Millisecond)
			ch <- "hello"
		}
		close(ch) // 放入5条数据后关闭
	}()
 	// 超过channel长度继续写数据会阻塞，主goroutine会进行取，另一个goroutine进行写
	for recv := range ch {
		fmt.Println(recv) // 关闭可继续读取数据
	}
}
```

### select

go提供的select可以同时对多个channel进行监控，实现并发接收。当多个case里的channel同时有数据ready的时候，select会随机选择一个case进行处理。

PS：range操作可以在channel关闭后自动退出，而select不会。所以在用for循环搭配select实现轮询时，select的case语句中必须显示的判断channel是否已经关闭，并做相应的处理，否则select每次从处于closed状态的channel中取出空值，并且继续执行case语句包含的body，程序的运行就可能与期望不一致

``` javascript

func main() {
	var ch = make(chan string, 2)
	go func() {
		for i := 0; i < 5; i++ {
			time.Sleep(1000 * time.Millisecond)
			ch <- "hello"
		}
		close(ch)
	}()
 
	for {
		select {
		case recv, ok := <-ch:
			if !ok { // 显示的判断，是否关闭
				os.Exit(0)
			}
			fmt.Println(recv)
		}
	}
 
}
```

### 并发循环

``` javascript
func main() {
	list := []int{0, 1, 2, 3, 4}
	sizes := make(chan int)
	var wg sync.WaitGroup
	for e := range list {
		wg.Add(1)
		go func(e int) {
			defer wg.Done()
			sizes <- e
		}(e)
	}
 
	go func() {
		wg.Wait()
		close(sizes)
	}()
 
	var total int
	for num := range sizes {
		total += num
	}
	fmt.Println(total)
}
```
根据list的长度启动多个goruntine，每个gouruntine的处理就是向非缓冲channel中写入一个数据，main goruntine取到所有数据后打印total退出

1.sync.WaitGroup来做计数，每启动一个goruntine计数器加1，每个goruntine完成时用wg.Done()将计数器减1，还有一个额外的goruntine在监控计数器的变化（阻塞直到计数器减到0

2.如果所有的goruntine都完成了数据发送并退出，额外的goruntine将会关闭channel

3.main goruntine对channel的range操作一旦检测到channel被关闭便会立即退出

场景：使用并发循环，但是不知道迭代次数时

1.监控计数器的处理必须放到一个单独的goruntine中，因为Wait()会阻塞当前goruntine直到计数器变为0。

2.Add()操作可以加负数。无论是Add()还是Done()，如果操作会使计数器变为负数则会出发panic异常

### 关于 gorountine 退出

扫描磁盘空间例子

``` javascript
package main
 
import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)
 
//限制同时打开的目录文件数，防止启动过多的goruntine
var sema = make(chan struct{}, 20)
 
//用于取消整个磁盘扫描任务
var done = make(chan struct{})
 
func walkDir(dir string, n *sync.WaitGroup, fileSizes chan<- int64) {
	defer n.Done()
	//收到cancel信号后，goruntine直接退出
	if cancelled() {
		return
	}
	for _, entry := range dirents(dir) {
		if entry.IsDir() {
			n.Add(1)
			subdir := filepath.Join(dir, entry.Name())
			go walkDir(subdir, n, fileSizes)
		} else {
			fileSizes <- entry.Size()
		}
	}
}
 
func dirents(dir string) []os.FileInfo {
	select {
	case sema <- struct{}{}:
	case <-done:
		//发出cancel后，我们期望是这个工作能立即被终止，但是对于已经启动的goruntine，dirents会继续执行并耗费不少时间
		//所以这里添加对cancel信号的处理，可以减少cancel操作的时延
		return nil
	}
 
	defer func() {
		<-sema
	}()
 
	entries, err := ioutil.ReadDir(dir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "du1: %v\n", err)
		return nil
	}
	return entries
}
 
func inputDir() string {
	var (
		inputReader *bufio.Reader
		dir         string
		err         error
	)
 	// inputReader，获取用户输入
	inputReader = bufio.NewReader(os.Stdin)
	// 打印提示
	fmt.Printf("Please input a directory:")
	// 读取用户输入
	dir, err = inputReader.ReadString('\n')
	// 遇到错误退出
	if err != nil {
		os.Exit(1)
	}
	// 处理文件路径
	dir = strings.Replace(dir, "\n", "", -1)
	//返回文件路径
	return dir
}
 
func printDiskUsage(nFiles int64, nBytes int64) {
	fmt.Printf("%d files %.1f GB\n", nFiles, float64(nBytes)/1e9)
}
 
func cancelled() bool {
	select {
	case <-done:
		return true
	default:
		return false
	}
}
 
func main() {
	// 开始执行工作，打印开始执行
	fmt.Println("=========Enter, walk.Test.()==========")
	// defer最后结束执行，打印结束工作
	defer fmt.Println("=========Exit, walk.Test.()==========")
	// 程序输入
	dir := inputDir()
 
	//从标准输入读到任何内容后，关闭done这个channel
	go func() {
		os.Stdin.Read(make([]byte, 1))
		close(done)
	}()
 
	fileSizes := make(chan int64)
	var n sync.WaitGroup
	n.Add(1)
	go walkDir(dir, &n, fileSizes)
 
	go func() {
		n.Wait()
		close(fileSizes)
	}()
 
	var nFiles, nBytes int64
	var tick <-chan time.Time
	tick = time.Tick(100 * time.Millisecond)
 
loop:
	for {
		select {
		case <-done:
			for range fileSizes {
				//do nothing，这个for循环的意义在于：收到cancel信号后，统计工作马上结束，我们会退出对fileSizes这个channel的接收操作，但是整个程序未必退出
				//这时将fileSizes排空可以防止还在运行walkDir的goruntine因为向fileSies发送数据被阻塞（没有buffer或者buffer已满），导致goruntine泄露
			}
			return
		case size, ok := <-fileSizes:
			if !ok { //这里必须显示的判断fileSizes是否已经被close
				break loop
			}
			nFiles++
			nBytes += size
		case <-tick: //每0.1S产生一次时钟信号，打印一次当前统计数字
			printDiskUsage(nFiles, nBytes)
		}
	}
 
	printDiskUsage(nFiles, nBytes)
	close(sema)
}

```

1.新建一个done channel用于取消整个磁盘扫描任务，新建一个sema channel， 限制20个，限制同时打开的目录文件数

2.打印开始，defer打印结束

3.输入文件路径inputDir：

根据 inputReader，获取用户输入， inputReader.ReadString('\n')读取用户输入， 遇到错误退出，处理并返回文件路径

4.用于关闭done chanel 从标准输入读到任何内容后，关闭done这个channel，用于主任务监控，关闭说明任务结束

5.初始化file的channel

6.开始计数，计数+1，启动goroutine 对于文件work。传入输入的文件路径，传入计数指针，用于修改计数，传入file的chaannel

	工作的函数：
	1.defer，进行计数，最后计数减一
	2.判断主done channel是否要关闭，防止work goroutine在主任务结束后，继续执行
	3.根据文件路径获取文件列表 []os.FileInfo， dirents
		1.select监控，一种是监控到 done里有信号要退出，收到信号直接return nil，结束后续运行
		  一种是往sema里写入一个空值，用来代表有一个目录文件被打开
		2.函数最后取出sema的数据
		3.读取文件路径，返回当前路径的文件列表，最后第二步，取出sema的数据
	4.遍历出来的文件，判断是不是文件夹，不是把大小放到file channel里，是的话，计数加1
	5.再启一个goroutine 继续work子路径，传入新得到的路径，计数，filechannel
	PS:外面计数+1，work执行结束，减一， 如果有子路径，加1，进入子路径，结束后减1，最后都没有文件夹了，则计数为0

7.单启一个goroutine，看计数，Wait()会阻塞当前goruntine直到计数器变为0，最后关闭file channel

8.声明一个tick channel time.Time格式

9.loop循环开启， select监听多个channel：
    1.done channel收到信号，统计工作结束
    2.file channel取出数据，判断file channel是否被关闭，然后取出数据统计
    3.tick channel，打印当时数据
    4.for循环结束，打印最终数据

10.最后程序退出

### close关闭

close 内置函数关闭一个通道，该通道必须是双向的或仅发送的

``` javascript
ch1 := make(chan int, 10)
ch2 := make(chan<- int, 10)
ch3 := make(<-chan int, 10)
close(ch1)
close(ch2)
close(ch3)
```
关闭 channel3将panic cannot close receive-only channel

channel 应该由发送的一方执行，由接收 channel 的一方关闭

### done channel

用于主协程通知子协程取消的需求
``` javascript
func main() {
    messages := make(chan int, 10)
    done := make(chan bool)

    defer close(messages)
    // consumer
    go func() {
        ticker := time.NewTicker(1 * time.Second)
        for _ = range ticker.C {
            select {
            case <-done:
                fmt.Println("child process interrupt...")
                return
            default:
                fmt.Printf("send message: %d\n", <-messages)
            }
        }
    }()

    // producer
    for i := 0; i < 10; i++ {
        messages <- i
    }
    time.Sleep(5 * time.Second)
    close(done)
    time.Sleep(1 * time.Second)
    fmt.Println("main process exit!")
}
```

上述例子中定义了一个buffer为0的channel done,子协程运行着定时任务。

如果主协程需要在某个时刻发送消息通知子协程中断任务退出，那么就可以让子协程监听这个done channel，一旦主协程关闭done channel，那么子协程就可以推出了，这样就实现了主协程通知子协程的需求


## channel原理

### 初始化

src/runtime/chan.go里

``` javascript
type hchan struct {
    qcount   uint           // total data in the queue
    dataqsiz uint           // size of the circular queue
    buf      unsafe.Pointer // points to an array of dataqsiz elements
    elemsize uint16
    closed   uint32
    elemtype *_type // element type
    sendx    uint   // send index
    recvx    uint   // receive index
    recvq    waitq  // list of recv waiters
    sendq    waitq  // list of send waiters

    // lock protects all fields in hchan, as well as several
    // fields in sudogs blocked on this channel.
    //
    // Do not change another G's status while holding this lock
    // (in particular, do not ready a G), as this can deadlock
    // with stack shrinking.
    lock mutex
}

```

make的时候，会申请一块内存，创建一个hchan结构体，返回执行该内存的指针，所以获取的的ch变量本身就是一个指针，在函数之间传递的时候是同一个channel


核心的部分是存放channel数据的环形队列，由qcount和elemsize分别指定了队列的容量和当前使用量


如果是带缓冲区的chan，则缓冲区数据实际上是紧接着Hchan结构体中分配的。

``` javascript
c = (Hchan*)runtime.mal(n + hint*elem->size);

```

使用两个list保存像该chan发送和从该chan接收数据的goroutine，还有一个mutex来保证操作这些结构的安全

recvq和sendq两个链表，一个是因读这个通道而导致阻塞的goroutine，另一个是因为写这个通道而阻塞的goroutine。如果一个goroutine阻塞于channel了，那么它就被挂在recvq或sendq中

队列中的每个成员是一个SudoG结构体变量

``` javascript
struct    SudoG
{
    G*    g;        // g and selgen constitute
    uint32    selgen;        // a weak pointer to g
    SudoG*    link;
    int64    releasetime;
    byte*    elem;        // data element
};
```

结构中主要的就是一个g和一个elem

elem用于存储goroutine的数据

读通道时，数据会从Hchan的队列中拷贝到SudoG的elem域

写通道时，数据则是由SudoG的elem域拷贝到Hchan的队列中

### 读写操作


``` javascript
c <- v
void runtime·chansend(ChanType *t, Hchan *c, byte *ep, bool *pres, void *pc)
```
c就是channel
ep是取变量v的地址
pres 用于select操作中

``` javascript
G1： c <- task
G2： task := <- ch
```

G1是写入,发送者
G2是读取，接收者

流程：

写：

1.初始的时候hchan结构体的buf为空，sendx和recvx都为0

2.G1向ch里发送数据的时候，会首先对buf加锁

3.将要发送的数据copy到buf里，并增加sendx的值

4.最后释放buf的锁

读：

1.G2消费的时候首先对buf加锁

2.然后将buf里的数据copy到task变量对应的内存里，增加recvx

3.最后释放锁

PS：整个过程，G1和G2没有共享的内存，底层通过hchan结构体的buf，使用copy内存的方式进行通信，最后达到了共享内存的目的

G2的消费速度应该是慢于G1的，所以buf的数据会越来越多，这个时候G1再向ch里发送数据，这个时候G1就会阻塞

### 阻塞

channel会区分是同步还是异步。

同步是指chan是不带缓冲区的，因此可能写阻塞，而异步是指chan带缓冲区，只有缓冲区满才阻塞

写阻塞：

1.G1向buf已经满了的ch发送数据的时候，当runtine检测到对应的hchan的buf已经满

2.会通知调度器，调度器会将G1的状态设置为waiting

3.移除与线程M的联系，然后从P的runqueue中选择一个goroutine在线程M中执行

4.G1就是阻塞状态，但是不是操作系统的线程阻塞

5.G1变为waiting状态后，会创建一个代表自己的sudog的结构，然后放到sendq这个list中

6.sudog结构中保存了channel相关的变量的指针

PS： 如果该Goroutine是sender，那么保存的是待发送数据的变量的地址，如果是receiver则为接收数据的变量的地址，之所以是地址，前面我们提到在传输数据的时候使用的是copy的方式

7.G2从ch中接收一个数据时，会通知调度器，设置G1的状态为runnable，然后将加入P的runqueue里，等待线程执行

### 空通道

G2先运行，读阻塞：

1.G2会从一个empty的channel里取数据，这个时候G2就会阻塞

2.G2也会创建一个sudog结构体，保存接收数据的变量的地址，但是该sudog结构体是放到了recvq列表里

3.当G1向ch发送数据的时候，runtime并没有对hchan结构体题的buf进行加锁，而是直接将G1里的发送到ch的数据copy到了G2 sudog里对应的elem指向的内存地址

PS：读一个关闭的通道，永远不会阻塞，会返回一个通道数据类型的零值。这个实现也很简单，将零值复制到调用函数的参数ep中。写一个关闭的通道，则会panic。关闭一个空通道，也会导致panic

### select实现

select-case中的chan操作编译成了if-else

``` javascript
select {
case v = <-c:
        ...foo
default:
        ...bar
}
```
会被编译为：
``` javascript
if selectnbrecv(&v, c) {
        ...foo
} else {
        ...bar
}
```

selectnbrecv函数调用runtime.chanrecv函数，只不过设置了一个参数，告诉当runtime.chanrecv函数，当不能完成操作时不要阻塞，而是返回失败

select操作其实都仅仅是被换成了if-else判断，底层调用的不阻塞的通道操作函数

#### select随机性

``` javascript
struct    Scase
{
    SudoG    sg;            // must be first member (cast to Scase)
    Hchan*    chan;        // chan
    byte*    pc;            // return pc
    uint16    kind;
    uint16    so;            // vararg of selected bool
    bool*    receivedp;    // pointer to received bool (recv2)
};

struct    Select
{
    uint16    tcase;            // 总的scase[]数量
    uint16    ncase;            // 当前填充了的scase[]数量
    uint16*    pollorder;        // case的poll次序
    Hchan**    lockorder;        // channel的锁住的次序
    Scase    scase[1];        // 每个case会在结构体里有一个Scase，顺序是按出现的次序
};
```

1.每个select都对应一个Select结构体

2.在Select数据结构中有个Scase数组，记录下了每一个case，而Scase中包含了Hchan。

3.然后pollorder数组将元素随机排列，将Scase乱序

## CSP模型

用于描述两个独立的并发实体通过共享的通讯 channel(管道)进行通信的并发模型

golang 通过goroutine和channel实现

Goroutine 是实际并发执行的实体，底层是使用协程(coroutine)实现并发，coroutine是一种运行在用户态的用户线程

1.用户空间 避免了内核态和用户态的切换导致的成本

2.可以由语言和框架层进行调度

3.更小的栈空间允许创建大量的实例

channel 是被单独创建并且可以在进程之间传递，它的通信模式类似于 boss-worker 模式的

一个实体通过将消息发送到channel 中，然后又监听这个 channel 的实体处理，两个实体之间是匿名的，这个就实现实体中间的解耦

其中 channel 是同步的一个消息被发送到 channel 中，最终是一定要被另外的实体消费掉的，在实现原理上其实是一个阻塞的消息队列