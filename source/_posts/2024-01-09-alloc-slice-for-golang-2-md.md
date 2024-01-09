---
title: Golang 中预分配 slice 内存对性能的影响（续）
date: 2024-01-09 08:16:22
tags: [性能, golang]
---

- [基础性能测试](#基础性能测试)
- [整个 Slice Append](#整个-slice-append)
- [复用 Slice](#复用-slice)
- [sync.Pool](#syncpool)
- [bytebufferpool](#bytebufferpool)
- [总结](#总结)

之前写了一篇 [Golang 中预分配 slice 内存对性能的影响](https://oilbeater.com/2023/07/19/pre-alloc-slice-for-golang/)，探讨了一下再 Slice 中预分配内存对性能的影响，之前考虑的场景比较简单，最近又做了一些其他测试，补充一下进一步的信息。包括整个 Slice append，sync.Pool 对性能的影响。

# 基础性能测试

最初的 BenchMark 代码，只考虑了 Slic 是否初始化分配空间的情况，具体的代码如下：

```go
package prealloc_test
 
import (
    "sync"
    "testing"
)
 
var length = 1024
var testtext = make([]byte, length, length)
 
func BenchmarkNoPreallocateByElement(b *testing.B) {
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        // Don't preallocate our initial slice
        var init []byte
        for j := 0; j < length; j++ {
            init = append(init, testtext[j])
        }
    }
}
 
func BenchmarkPreallocateByElement(b *testing.B) {
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        // Preallocate our initial slice
        init := make([]byte, 0, length)
        for j := 0; j < length; j++ {
            init = append(init, testtext[j])
        }
    }
}
```

测试结果如下：

```bash
BenchmarkNoPreallocateByElement-12        569978              2151 ns/op            3320 B/op          9 allocs/op
BenchmarkPreallocateByElement-12          804807              1304 ns/op            1024 B/op          1 allocs/op
```

可见没有预分配的情况下多了 8 次内存分配，两个相对比可以粗略的认为 40% 的时间消耗在了这额外的 8 次内存分配。

这两个测试用例使用的是循环里逐个 append 元素，但是 Slice 还支持整个 Slice 进行 append 在这种情况下的性能差距是没有体现出来的。而且在这两个测试用例里我们其实无法知道内存分配所占的时间消耗占整个时间的占比。

# 整个 Slice Append

因此加入两个整个 Slice Append 的测试用例，观察预分配内存对性能还有没有这么大的影响。新增的用例代码如下：

```go

func BenchmarkNoPreallocate(b *testing.B) {
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        // Don't preallocate our initial slice
        var init []byte
        init = append(init, testtext...)
    }
}
 
func BenchmarkPreallocate(b *testing.B) {
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        // Preallocate our initial slice
        init := make([]byte, 0, length)
        init = append(init, testtext...)
    }
}
```

测试结果如下：

```bash
BenchmarkNoPreallocateByElement-12        569978              2151 ns/op            3320 B/op          9 allocs/op
BenchmarkPreallocateByElement-12          804807              1304 ns/op            1024 B/op          1 allocs/op
BenchmarkNoPreallocate-12                3829890               311.5 ns/op          1024 B/op          1 allocs/op
BenchmarkPreallocate-12                  3968048               306.7 ns/op          1024 B/op          1 allocs/op
```

可见两个用例都只用了一次内存分配，消耗时间几乎相同，而且大幅低于逐个元素进行 append 的情况。一方面整个 Slice append，在 Slice 扩容时就知道了最终的大小没必要进行动态内存分配，降低了内存分配的开销。另一方面整个 Slice append 在实现上会进行整段复制，降低了循环的开销，性能会提升很多。

但在这里每次还是会有一次内存分配，我们依然无法确定这一次内存分配所占的整体时间比例。

# 复用 Slice

为了计算一次内存分配的消耗，我们设计一个新的测试用例，将 Slice 的创建放到循环外，循环内每次最后将 Slice 的 length 设为 0，给下次进行复用。这样在大量的测试下只会进行一次内存分配，平均下来就可以忽略不计了。具体的代码如下：

```go
func BenchmarkPreallocate2(b *testing.B) {
    b.ResetTimer()
    init := make([]byte, 0, length)
    for i := 0; i < b.N; i++ {
        // Preallocate our initial slice
        init = append(init, testtext...)
        init = init[:0]
    }
}
```

测试结果如下：

```bash
BenchmarkNoPreallocateByElement-12        514904              2171 ns/op            3320 B/op          9 allocs/op
BenchmarkPreallocateByElement-12          761772              1333 ns/op            1024 B/op          1 allocs/op
BenchmarkNoPreallocate-12                4041459               320.9 ns/op          1024 B/op          1 allocs/op
BenchmarkPreallocate-12                  3854649               320.1 ns/op          1024 B/op          1 allocs/op
BenchmarkPreallocate2-12                63147178                18.63 ns/op            0 B/op          0 allocs/op
```

可见这次测试统计上没有内存分配了，整体消耗时间也降为了之前的 5%。因此大致可以计算出在之前的测试用例里每一次内存分配会消耗 95% 的时间，这个占比还是很惊人的。因此对于性能敏感的场景还是需要尽可能的复用对象，避免反复的对象创建的内存开销。

# sync.Pool

简单的场景下可以像上个测试用例里一样手动的清空 Slice 在循环内进行复用，但是真实场景里对象的创建通常会发生在代码的各个地方，就需要统一的进行管理和复用了，Golang 里的 `sync.Pool` 就是做这个事情的，而且使用起来也很简单。但是内部实现还是比较复杂的，为了性能进行了大量无锁化的设计，具体实现可以参考[https://www.cyhone.com/articles/think-in-sync-pool/](https://www.cyhone.com/articles/think-in-sync-pool/)。

使用 `sync.Pool` 重新设计的测试用例如下：

```go
var sPool = &sync.Pool{
    New: func() interface{} {
        return make([]byte, 0, length)
    },
}
 
func BenchmarkPool(b *testing.B) {
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        // Don't preallocate our initial slice
        buf := sPool.Get().([]byte)
        buf = append(buf, testtext...)
        buf = buf[:0]
        sPool.Put(buf)
    }
}
```

其中 `New` 用来给 `sync.Pool` 一个在没有可用对象时创建对象的构造函数，使用的时候使用 `Get` 方法从 Pool 里获取一个对象，用完了再用 `Put` 方法把对象还给 `sync.Pool`。这里主要注意一下对象的生命周期，以及放回到 `sync.Pool` 时需要清空对象，避免脏数据。测试结果如下：

```bash
BenchmarkNoPreallocateByElement-12        522565              2129 ns/op            3320 B/op          9 allocs/op
BenchmarkPreallocateByElement-12          781638              1311 ns/op            1024 B/op          1 allocs/op
BenchmarkPoolByElement-12                 957424              1233 ns/op              24 B/op          1 allocs/op
BenchmarkNoPreallocate-12                4057801               310.3 ns/op          1024 B/op          1 allocs/op
BenchmarkPreallocate-12                  3841848               315.4 ns/op          1024 B/op          1 allocs/op
BenchmarkPreallocate2-12                63356907                18.76 ns/op            0 B/op          0 allocs/op
BenchmarkPool-12                        13784712                85.19 ns/op           24 B/op          1 allocs/op
```

可见 `sync.Pool` 还是有少量的内存分配，并且性能消耗会比手动复用 Slice 要高一些，不过考虑到使用的便利性以及相比不使用还是有明显的性能提升还是一个不错的方案。

但是直接使用 `sync.Pool` 也有下面两个问题：

1. 对于 Slice 的情况 `New` 分配的初始内存是固定的，运行时使用空间超出的话，可能还会有大量动态的内存分配调整。
2. 另一个极端是 Slice 被动态扩容很大后放回到 `sync.Pool` 中，可能会造成内存的泄漏和浪费。

# bytebufferpool

为了达到实际运行时更优的性能，[bytebufferpool](https://github.com/valyala/bytebufferpool) 这个项目在 `sync.Pool` 的基础上运用了一些简单的统计规律，尽可能的减少了上面提到的两个问题在运行时的影响。（该项目的作者是俄罗斯人，手下还有 fasthttp, quicktemplate 和 VictoriaMetrics 几个项目，个顶个都是性能优化的优秀案例，战斗民族经常会搞这种性能推极限的项目。

代码里主要的结构如下：

```go
// bytebufferpool/pool.go
const (
  minBitSize = 6 // 2**6=64 is a CPU cache line size
  steps      = 20
 
  minSize = 1 << minBitSize
  maxSize = 1 << (minBitSize + steps - 1)
 
  calibrateCallsThreshold = 42000
  maxPercentile           = 0.95
)
 
type Pool struct {
  calls       [steps]uint64
  calibrating uint64
 
  defaultSize uint64
  maxSize     uint64
 
  pool sync.Pool
}
```

其中 `defaultSize` 的作用是 `New` 的时候给 Slice 分配的大小，`maxSize` 的作用是超过这个大小的 Slice `Put` 时会拒绝。核心的算法其实就是在运行时根据统计到的 Slice 使用大小信息动态的去调整 `defaultSize` 和 `maxSize` ，避免额外的内存分配同时还要避免内存泄漏。

这个动态统计的过程也比较简单，就是将 `Put` 到 Pool 里的 Slice 大小划分了 20 个区间范围进行统计，当 `Put` 次数达到 `calibrating` 后就进行一次排序，将这个时间段内使用最为频繁的区间大小作为 `defaultSize` 这样在统计上就可以避免不少额外的内存分配。然后按大小排序，将 95% 分位大小设置为  `maxSize`，这样就避免了在统计上长尾大的对象进入 Pool。就靠着这样动态调整这两个值，在统计上可以在运行时获得更优的性能。

# 总结

- Slice 初始化尽可能指定 capacity
- 避免在循环中初始化 Slice
- 性能敏感路径考虑使用 sync.pool
- 内存分配的性能开销可能远大于业务逻辑
- bytebuffer 的复用可以考虑看下 bytebufferpool