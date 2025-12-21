---
title: 周报 2 —— 开源 and AI
date: 2025-12-21 20:43
created:
  - 2025-12-21
tags:
  - weekly
---

## 开源

最近社区的 PR 越来越多，由于 AI 的增强，每个 PR 膨胀的也很厉害，Review 的难度也越来越大。一直以来我对 PR 的合并手都比较松，现在合并一个新功能不强制有 proposal，不强制有测试，文档有时候甚至都是我后来再写的。如果从教条的开源社区规范来看，这个项目的治理，社区，文档都是乱哄哄的。代码债也到处都是，我最近初步梳理了几个文件就费了好大的劲。如果不是借助 AI 好多重构的活会更难。

不过从我的价值倾向来看，相比规范性，我更注重的还是一个项目是不是真的有用。尽管不规范会带来长期的隐患，但是保持这个项目一直有用就有机会等到后人有智慧来解决。

## AI

最近在反思之前用 AI 的一些方法，在习惯了自己不动手一把梭后，感觉自己阅读代码和复杂内容的耐心也下降了。或许以后确实 AI 可以做所有脑力劳动了，那么脑力劳动可能就变成现在的健身房了，未来人类需要和现在刻意锻炼肌肉一样才能保证脑力不流失。

[happy](https://github.com/slopus/happy) 一个能在手机上控制开发机上 codex 和 claude code 的工具，这样不在电脑前也能抽 AI 干活了。

## 健身

10kg 哑铃片到货，视觉上还是有些吓人。

![](../images/20251221192028.png)

全程的引体向上还是做不了，不过肩胛骨旋转的感觉找到一些了，离心可以做全程了。

连续三周上重量后，这周五的时候明显感觉硬拉拉不动了，下周打算做个减载周。

## 技术

[OpenShift Roadmap](https://www.youtube.com/watch?v=nFuEy9D4GGM) OpenShift 更新了未来一年的 RoadMap，公司里如果还有上了年纪的人可能会关心。

[A new hash table ](https://valkey.io/blog/new-hash-table/) 是 Valkey 的一个 hash table 实现变种，主要目的是为了节省内存体积和内存访问次数。这种把数组和链表组合的思路能够兼顾顺序访问的效率和链表无限扩容还是挺有意思。不过后来又看了下其他的 hash table 实现，发现这好像就是 Golang 在使用 Swiss Table 之前的实现。

[kubevirtbmc]( https://github.com/starbops/kubevirtbmc) 一个对接 KubeVirt 和传统物理机 BMC 协议的工具，能把 IPMI 和 Redfish API 的调用转换成 KubeVirt 的 API。这样用就能复用之前管理物理机的工具和流程来管理 KubeVirt 的虚拟机了。

[Performance Hints](https://abseil.io/fast/hints.html) Jeff Dean 和另一个 Google 初创时的工程师 [Sanjay Ghemawat](https://research.google/people/sanjayghemawat/) 写的性能优化手册。和大部分性能优化都是先 profile 找到热点再优化不同，这个手册介绍的主要是火焰图上看不到热点的时候如何怎么榨取性能。 因此里面介绍的全都是微操，针对 common case 做 fast path 已经算是最大块的优化方法了。里面有不少在 search 和 tensorflow 上做微操的例子，看上去还是很过瘾的。

## 生活

海底捞的海螺片和鞭炮笋很好吃，推荐尝试，新出的猪肉卷就不要试了。另一个感叹是海底捞现在已经变成了个家庭聚餐的地方，满屋子都是过生日的，而在几年前我一直以为这是个工作或者同学聚餐的地方。

中午逛公园走了条平时没走的小路，上了段城墙，然后发现了传说中的“蓟门烟树”，我一直以为是什么古树，原来是个石碑，看介绍是乾隆题的字。

![](../images/68598f7ac4dc3dcf030684b75d8e4af5.jpg)

去了平西府地铁站新开的小站公园，公园用的一个人物形象名字是“下腰女孩（Tireless Girl）”。虽然我能勉强搞明白下腰和 Tireless 的关系，但这个翻译实在是太奇怪了。

![](../images/6ad0dd8d1e1f02966a5221d9cd2ab8ac.jpg)
