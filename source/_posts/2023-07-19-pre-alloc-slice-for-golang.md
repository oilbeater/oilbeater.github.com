---
title: Golang 中预分配 slice 内存对性能的影响
date: 2023-07-19 10:48:09
tags: [性能, golang]
---

- [Slice 内存分配理论基础](#slice-内存分配理论基础)
- [定量测量](#定量测量)
- [Lint 工具 prealloc](#lint-工具-prealloc)
- [总结](#总结)


在我代码 review 的过程中经常会关注代码里 slice 的初始化是否分配了预期的内存空间，也就是凡是 `var init []int64` 的我都会要求尽可能改成 `init := make([]int64, 0, length)` 格式。但是这个改进对性能究竟有多少影响并没有什么定量的概念，只是教条的去要求。这篇博客会介绍一下预分配内存提升性能的理论基础，定量测量，和自动化检测发现的工具。

# Slice 内存分配理论基础

Golang Slice 扩容的代码在[slice.go 下的 growslice](https://github.com/golang/go/blob/go1.20.6/src/runtime/slice.go#L157)。大体思路是在 Slice 容量小于 256 时
每次扩容会创建一个容量翻倍的新 slice；当容量大于 256 后，每次扩容会创建一个容量为原先的 1.25 倍的新 slice。之后会将旧 slice 的数据复制到新的 slice，最终返回新的 slice。

扩容的代码如下：
```go
	newcap := oldCap
	doublecap := newcap + newcap
	if newLen > doublecap {
		newcap = newLen
	} else {
		const threshold = 256
		if oldCap < threshold {
			newcap = doublecap
		} else {
			// Check 0 < newcap to detect overflow
			// and prevent an infinite loop.
			for 0 < newcap && newcap < newLen {
				// Transition from growing 2x for small slices
				// to growing 1.25x for large slices. This formula
				// gives a smooth-ish transition between the two.
				newcap += (newcap + 3*threshold) / 4
			}
			// Set newcap to the requested cap when
			// the newcap calculation overflowed.
			if newcap <= 0 {
				newcap = newLen
			}
		}
	}
```

因此理论上如果预分配好 slice 的容量，不需要动态扩张我们可以在好几个地方有性能的提升：

1. 内存只需要一次分配，不需要反复分配。
2. 不需要反复进行数据复制。
3. 不需要反复对旧的 slice 进行垃圾回收。
4. 内存准确分配，不存在动态分配导致的容量浪费。

理论上来看，预分配 slice 容量相比动态分配会带来性能提升，但具体提升有多少就需要定量测量了。

# 定量测量

我们参考 [prealloc](https://github.com/alexkohler/prealloc/blob/master/prealloc_test.go) 的代码进行简单修改来测量不同容量的 slice 预分配和动态分配对性能的影响。

测试代码如下，通过修改 `length` 可以观察不同情况下的性能数据：

```go title="prealloc_test.go"
package prealloc_test

import "testing"

var length = 1000

func BenchmarkNoPreallocate(b *testing.B) {
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Don't preallocate our initial slice
		var init []int64
		for j := 0; j < length; j++ {
			init = append(init, 0)
		}
	}
}

func BenchmarkPreallocate(b *testing.B) {
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Preallocate our initial slice
		init := make([]int64, 0, length)
		for j := 0; j < length; j++ {
			init = append(init, 0)
		}
	}
}
```

第一个函数测试动态分配的性能，第二个函数测试预分配的性能。通过下面的命令可以执行测试：

```bash
go test -bench=. -benchmem prealloc_test.go
```

在 `length = 1` 情况下的结果：

```bash
BenchmarkNoPreallocate-12       40228154                27.36 ns/op            8 B/op          1 allocs/op
BenchmarkPreallocate-12         55662463                19.97 ns/op            8 B/op          1 allocs/op
```

在 `length` 为 1 的情况下，理论上动态分配和静态分配都要进行一次初始化的内存分配，性能不应该有差异，但是实测下来，预分配的耗时为动态分配的 70%，即使在两者内存分配次数一直的情况下，预分配依然有 1.4x 的性能优势。目测性能提升和变量的连续分配相关。

在 `length = 10` 情况下的结果：

```bash
BenchmarkNoPreallocate-12        5402014               228.3 ns/op           248 B/op          5 allocs/op
BenchmarkPreallocate-12         21908133                50.46 ns/op           80 B/op          1 allocs/op
```

在 `length`` 为 10 的情况下，预分配依然只进行了一次性能分配，动态分配进行了 5 次性能分配，预分配的性能是动态分配性能的 4 倍。可见即使在 slice 规模较小的时候，预分配依然会有比较明显的性能提升。

下面是在 `length` 分别为 129,1025 和 10000 情况下的测试结果：

```bash
# length = 129
BenchmarkNoPreallocate-12         743293              1393 ns/op            4088 B/op          9 allocs/op
BenchmarkPreallocate-12          3124831               386.1 ns/op          1152 B/op          1 allocs/op

# length = 1025
BenchmarkNoPreallocate-12         169700              6571 ns/op           25208 B/op         12 allocs/op
BenchmarkPreallocate-12           468880              2495 ns/op            9472 B/op          1 allocs/op

# length = 10000
BenchmarkNoPreallocate-12          14430             86427 ns/op          357625 B/op         19 allocs/op
BenchmarkPreallocate-12            56220             20693 ns/op           81920 B/op          1 allocs/op
```

在更大容量下，静态分配依然只做一次内存分配，但是性能提升并没有相应成倍增长，整体性能会是动态分配的 2 到 4 倍。应该是在这个过程中有一些其他的消耗，或者 golang 对大容量的复制有特殊的优化，因此性能差距并没有拉大。

当把 slice 的内容换成更复杂的 struct 时，原以为复制会带来更大的性能开销，但实测复杂 struct 预分配和动态分配的性能差距反而更小，看上去还是有很多内部的优化，表现和直觉并不一致。

# Lint 工具 prealloc

尽管预分配内存可以带来一定的性能提升，但是在比较大的项目中完全依赖人工去 review 这个问题很容易出现纰漏。这时候就需要用到一些 lint 工具来自动做代码扫描了。[prealloc](https://github.com/alexkohler/prealloc) 就是这样一个工具可以扫描潜在的能够预分配但却没有预分配的 slice，并且可以整合到 [golangci-lint](https://golangci-lint.run/usage/linters/#prealloc) 中。

# 总结

整体来看 slice 的内存预分配是个比较简单但却能有比较好优化效果的方法，即使在 slice 容量很小的情况下，预分配依然能有比较明显的性能提升。通过 prealloc 这种静态代码扫描工具，可以比较方便的实现这类潜在优化的检测并集成到 CI 中简化日后的操作。