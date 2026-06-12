---
title: DeepSeek Sparse Attention -- 给 Attention 加一个选择器
date: 2026-06-12 12:00:00
tags:
- DeepSeek
- Paper
---

回看 DeepSeek 从 V3 到 V4 的这一年里，如何降低长上下文的开销一直是研究的一个重点。从 V3.2 开始，DeepSeek 引入了 DSA，直接把 V3.1 的价格降低了 50%。这个技术在 V4 中也得到了延续，并成为实现 1M 上下文的关键技术之一。这里会谈一下我对 DSA 思路的理解。

## Full Attention

原始的 Attention 计算需要计算每个 Token 和它之前所有 Token 的相关性，得出当前 Token 在当前上下文的一个向量值，因此随着输入输出序列不断增加，整个 Attention 计算的复杂度趋近于 O(n^2)。

这也就意味着随着序列增长，总计算量会平方增长，这成为了一个主要的性能瓶颈，也是很多模型在超过一定序列长度后价格大幅上升的原因。为了解决 Full Attention 的二次方计算问题，就出现了很多 Sparse Attention 机制，试图避免成本的快速上升。

## Sparse Attention

为了避免二次方的 Attention 计算，一个很直接的想法就是只选择和当前 Token 关系最大的一批 Token 计算 Attention。这个想法不仅很符合直觉，在 Attention 的实际计算中也会发现序列里大部分 Token 和当前 Token 的关系计算值是接近于 0 的，我们在预测下一个 Token 时，很多时候只要看序列里的关键信息就可以了。

一个很直接的思路就是滑动窗口只计算附近 K 个 Token 的 Attention，这个方法的好处是简单，计算复杂度稳定，但是局限性也很明显，那就是会丢失长距离的信息。

为了解决长距离丢失的情况，还有一种分层的注意力机制，使用一部分 Token 作为全局 Token，再加上局部滑动窗口的 Token，用全局 Token 来弥补长距离的信息。但是这就带来了新的问题：这些少数的全局 Token 应该如何选择？随着序列变长、任务目标发生变化，全局 Token 是不是又该重新调整？

不管是滑动窗口还是分层的注意力其实都是通过简单的局部性策略选择 Token，并不是真正根据 Token 实际的相关性来选择 Token。其实 Attention 的计算过程中就会计算出 Token 之间的相关性分数，我们直接取其中的 Top-K 作为选择的 Token 是否可行呢？

当然可以，但此时 Attention 的计算已经完成了，再做 Top-K 已经没有多少优化的意义了。但是如果我们可以通过计算复杂度更低的方式来快速选择出 Top-K 再进行 Attention 计算就有意义了，这就是 DSA 试图做的事情。

## DeepSeek Sparse Attention

DSA 的核心组件是一个 Lightning Indexer 的选择器，它会根据当前 Token 给上下文的所有 Token 打一个分数，然后选择 Top-K 进入后续的 Attention 的计算。

而这个 Indexer 的分数计算就是去预测 Attention 计算的相关性分数。而它的结构也和 Attention 的结构很相似，Attention 是有 QKV 三个向量矩阵，而 Indexer 使用 WQK 三个向量矩阵，计算过程也是基本类似的。这就带来了一个新的疑问，这个 Indexer 其实是在模拟 Attention 的行为，那它的复杂度难道不应该和 Attention 是一致的吗？

按照我的理解，其实复杂度确实是一致的，还是 O(n^2)，但是这个 Indexer 由于任务简单可以使用更少的特征，更低的精度，ReLU 这样更高效的算子，在工程上把复杂度的常数部分大幅降低。这有点类似于用同样的股票预测模型结构，Attention 是要预测股票第二天的价格，Indexer 是要预测股票第二天涨跌的概率，把上涨概率最高的 Top-K 选择出来给 Attention 做价格预测。尽管结构上相似，但是预测涨跌概率的难度要比预测价格低很多，可以选择更少的参数和更快速的算法。由于 Indexer 是根据 Attention 结果来训练的，也可以粗略地理解为 Indexer 是从 Attention 蒸馏出来的。

## 总结

DSA 的本质是在 Attention 的计算前加了一个选择器，这个选择器需要尽可能精确地预测出哪些 Token 和当前 Token 相关，又需要尽可能低的计算复杂度避免选择器的复杂度接近 Attention 的复杂度。DSA 的做法是使用了和 Attention 类似的结构，使用更少的参数量和更高效的算子，以及只预测大小关系而不是预测具体分数来降低选择器的复杂度。尽管整体复杂度还是 O(n^2)，但是通过把常数项降低数十倍，实现了在不牺牲模型性能的情况下成本大幅下降。
