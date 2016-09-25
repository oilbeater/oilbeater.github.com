---
layout:	post
title:	"Borg 论文阅读笔记"
date:	2015-10-06 14:30:55
category:	"docker"
---

Borg 是在传说中流传已久的 Google 内部集群管理系统，现在火热的 Mesos 和 Kubnetes 都是源自于 Borg。今年 Google 把论文放出来了，第一遍读感觉通篇细节没有什么太多值得玩味的，在这个行当干了一阵再读发现细节是魔鬼，每个细节都对应这一个实际中难解的问题，再读第三遍，不得不做一些笔记了。

这篇论文发布在 EuroSys'15,可以去 这里 下载。虽说 EuroSys 已经算是极好的会议了，但是以 Google 的规模和 Borg 的名气没有中 OSDI/SOSP 大概是论文写得不好吧。建议从事容器和集群管理相关的同学都仔细看看这篇论文。

##概述

集群管理带来的好处大致都是那些东西（1）隐藏了底层故障的细节（2）高可靠高可用（3）在线离线任务混部，提高资源使用率。这套系统 Google 发展了十多年，从论文角度来看不是第一个这样的集群管理系统了，Mesos 和 Yarn 都很早就把论文放出来了。但是其实这两个系统都深受 Google 的影响，而且 Brog 可以调度上万台机器的集群，是现阶段唯一一个达到这个规模的系统。

###机器情况

介绍了一堆 cell，cluster，site 的概念，一个中等规模的 cell 有 10k 异构机器，一个 cluster 通常包含一个这样的 cell 和一些规模稍小的其他用途 cell，多个 cluster 构成了一个 site。机器的异构维度十分多，甚至包括 cpu 类型，是否有外部 IP， 是否有 flash，系统版本等等。值得注意的是 cell 中绝大多数的机器是没有虚拟化的，主要原因是在 Google 的规模虚拟化所带来的性能开销是不能忍受的，出于成本的考虑这些机器的处理器甚至是没有虚拟化功能的。

###负载

long running, latency-sensitive 服务，诸如 Gmail, Google Docs, Search, Big Table, latency 一般在几微妙到几百毫秒。（prod）

1. batch jobs，latency 一般在几秒到数天。（non-prod）

2. 其中 prod 类型的任务占据了 70% 的 CPU 资源和 60% 的内存资源。

论文中列举了 Borg 上运行的应用 MapReduce，FlumeJava, Millwheel， Pregel 这些之前都发表过论文的系统都在 Borg 上运行，分布式存储系统诸如 GFS，CFS，Bigtable，Megastore 也是在 Borg 中运行。论文里把之前发表过的系统都引了一遍，鄙视这种无意义刷引用数的行为。

由此可见像 Mapreduce 集群系统 GFS 分布式存储系统这种比较复杂的系统 Borg 都是可以支持的，而现在市面上的 CaaS 系统大多只支持简单的 Web 和单机的有状态服务，很多人也认为数据类和复杂的集群类服务不适合用 CaaS 来运行，Borg 论文中虽然没有解释如何支持这类服务，但至少告诉人们是有可行解决方案的。

### 任务情况

熟悉 docker 的这一部分接受起来应该会比较容易。每个 job 运行时需要指定所需资源，包括端口号，CPU 核数，内存，磁盘等等。每个 job 的 binary 都是静态链接的，这和 docker 的 image 很相似都是为了最大程度的减少环境依赖，做到一次 build 处处执行。

Borg 的使用者（主要是 Google 的 SRE（Site Reliable Engineer））多数情况下通过一个 CLI 来操作 Borg，感觉和 docker client 很像。对于复杂的编排需要使用 BCL 这种语言来编写脚本，BCL 还带有 lambda 可以提供数值计算，在 Google 中有大量这样的脚本，很多脚本都有 1k 行以上。感觉和 compose 有些像，论文里的说法是和 Auroa 的配置文件更像一些。
![](http://7xl5hp.com1.z0.glb.clouddn.com/lifecycle.png)
附上论文中的任务运行的生命周期图，和 docker 容器的生命周期十分类似，包括 kill 的时候先发送 SIGTERM 一段时间后再发送 SIGKILL 的设计都十分类似。


### 服务发现及监控

服务发现用的是 chubby 保存对应服务的主机名和端口，lb 设备通过查询 chubby 来获取最新的路由。这和现在外面普遍的 haproxy + etcd 的做法基本一致，不过 etcd 和 zk 虽说源自 chubby 的论文，但是 chubby 可以支撑这种上万服务的动态变化，不知道 zk 或者 etcd 现在的性能有没有这么好。

监控这块本以为会有什么出彩的设计，毕竟容器监控这块还是很棘手的，没想到 Google 简单粗暴要求每个 task 都需要运行一个 HTTP server 向外发布自己的状态信息和性能指标，果然是私有云可以靠标准化解决很多问题。

至于 Borg 本身的监控，Borg 会记录所有的 event 和细粒度的资源使用情况并用 Dremel 来进行数据分析和处理，顺便帮 Dremel 刷了一篇引用数。

### 一些杂项

Allocs 这个概念论文没说的太明白，感觉是类似于 Mesos 中 reserved offer 的概念，将一部分资源预留给之后的任务使用，减少了调度的时间。并可以将一组任务分配到一个 alloc 中，而一个 alloc 又是一个单机模型的概念，感觉又和 k8s 中的 pod 很类似，可以方便处理一些需要在同一台机器上运行的一组不同服务，例如一个 web server 和一个针对这个 web server 的 log 收集服务可以运行在同一个 alloc 中，就保证了他们在同一台机器运行。

Priority，quota，admission control 这些没有什么太特殊的，都是一些细枝末节的东西，感觉是为了撑字数。

## 架构
![](http://7xl5hp.com1.z0.glb.clouddn.com/borg_arthicture)
Borg 这种多 master 互备，在 slave 上部署 agent 的架构现在还是很常见的，Borg 的很多细节方面的设计使得它可以撑起 Google 级别的集群。Borg 所有的组件都是用 C++ 编写的。

### Borgmaster

每个 Borgmaster 由两个进程组成，master 和 scheduler。负责接收 client 的请求，管理所有任务的状态变化并和 borglet 进行通信。Borgmaster 由五个节点组成，其中一个是 leader 另外四个为 replica 保存大部分的状态，此外所有的状态都被被分到一个基于 Paxos 的存储系统中（不知道为啥这里又不用 chubby 了，难道 google 还有什么小秘密）。此外定时 checkpoint，故障恢复都是和 Paxos 协议所介绍的类似，没有什么太多值得说的。

有意思的是 Google 做了一个 Fauxmaster 可以读取 Borgmaster 的 checkpoint 文件并接收 client 的请求进行模拟仿真，客户端就仿佛和一个真的 Borgmaster 通信操作真实集群一样，这对于在线调试和一些生产环境操作的演练来说是个极好的工具。

### 调度

调度分为两部分（1）找到一组可以运行 task 的机器 （2）对每个机器打分，挑选最合适的机器运行任务。第一步很好理解，找到一组有剩余资源的机器，第二步考虑的因素就很多了，是否可能发生抢占，是否有当前任务的 binary package，是否在不同的可用域，当前机器的负载情况等等都会影响分数。在此之上再结合了 worst fit 和 best fit 两种打分机制进行打分。

在打分模型中最重要的因素是机器是否存在当前 task 的 binary package。按照论文的数据，每个任务的平均启动时间为 25s，其中 80% 的时间用于 package installation，可以近似理解为 docker pull image 的时间。因此 package 的局部性成为打分模型中最重要的因素。为了加速 package 的分发，Borg 内使用了树协议和 torrent-like 协议进行分发。现在 docker registry 也在致力于 p2p 的方式来 pull image，可能也是借鉴 Borg 的思想。

个人感觉 Borg 的 package 似乎没用 layer filesystem 的技术，不然可以标准化 package 的 base image，这样分发速度应该会快很多。而 docker 也跟着学 p2p 就有点看不懂它要干什么了，毕竟现在 pull 的瓶颈主要在 image 的解压。也有可能 docker 官方想通过这种方式降低 hub 流量的开销，或者想变相翻墙也是有可能的。

### Borglet

Borg 在每台机器上的 agent，除了管理 task 的生命周期外还做了资源管理，日志处理，系统监控等等一堆东西，感觉是个 mesos slave + docker daemon + logstash + cadvisor 多功能合一的重 agent。 Borglet 消息的汇报通过 master 轮询 Borglet 来实现，这样 master 可以控制访问的速度，避免在特殊情况下踩踏事件的发生，毕竟及其规模太大了， push 的方式很可能会出问题。此外 master 的 replica 并不是单纯的做 backup 为了分担 master 的压力，每个 replica 会分担一部分的 Borglet 通信任务，再由 master 进行汇总。

### 扩展性

按照论文的说法作者也不知道 Borg 这种集中控制的架构极限在哪里，因为他们总是能克服性能瓶颈。目前的处理速率为每分钟一万个 task，大概消耗 10~14 个 CPU 以及 50 GB 内存，这么看来一台稍微好点的机器就可以扛住了。

论文中提到了一些提高扩展性的改进，包括前面提到的将任务分散到 replica 中，使用类似于 Omega 的乐观并行调度，以及为不同类型的负载指定不同的调度器。

在提高响应速度方面主要是利用缓存保存调度计算的合适机器和每台机器的分数，避免重复的计算并且在计算出足够数量的机器后就停止计算，避免了遍历集群中所有机器。有了这些措施后每个调度基本可以在半秒内完成。

### 可用性

可用性达到 4 个 9，举了很多很细的例子，来说明如何提高可用性。包括自动的 reschedule，分可用域部署 job，限制同时并发的任务数来避免踩踏，job 的无状态化 等等。其中最重要的一个设计是保证已经运行的任务不会因为 Borgmaster 的挂掉而停止，这个也是 Mesos 在设计中的一个比较重要的原则。基本上按照最近的说法从 3 个 9 还可以靠运气和堆人肉，4 个 9 就需要进行良好的设计和自动化了，论文这一部分有很多很细节的方法都很值得参考。

## 经验教训

这一部分说是经验教训，其实是花了一页的论文来给 k8s 做广告。

### The bad

缺乏对多任务编排的能力，看描述的意思是一个 job 内部只能是同一个 task，当需要不同服务之间交互时需要一些复杂的 hack。k8s 提出的 pod 的概念就是为了解决这一类问题。

一台机器上的 task 共享 一个 IP 会把事情复杂化。调度系统需要将机器的 port 当做资源来对待，每个 job 也必须事先说明自己需要哪些 ports，Borglet 上需要对端口进行隔离（个人感觉这其实算不上太大的问题）。k8s 中利用了 Linux namespaces, IPv6 以及 SDN 技术来解决这个问题，每个 pod 和 服务都可以拿到唯一属于自己的 IP。

为 power user 提供了太多的选项使得普通用户使用起来比较麻烦（⊙﹏⊙ 我不懂为什么要写这条）。BCL 的 spec 里面有 230 个参数，为了方便普通用户专门有一个工具可以自动化的生成根据实验结果最优的配置。

### The good

Allocs 很有用，所以我们在 k8s 提供了 pod 作为 allocs 的更高级形式。

集群管理不只是任务管理，naming 以及 lb 都是集群管理中不可缺少的，所以我们在 k8s 中也提供了 naming 和 lb 机制。

各种监控和 debug 的工具十分重要，Borg 为整个 Google 提供服务，出问题都找 Borg 的维护人员会疯掉的，所以 Borg 提供了工具方便用户自己 debug 来解决问题。所以我们在 k8s 中提供了 cAdvisor，基于 Elasticsearch/Kibana/Fluentd 的日志汇集工具，master 状态快照等一系列 debug 工具。

Borg master 是分布式系统的核心，k8s 更进一步提供了 API server 并且是为服务的架构的可以更好的对机器生命周期进行管理。

总之这一部分就是 k8s 彻头彻尾的软文。

## 总结

尽管读了三遍这依然是一篇很碎很碎的论文，Google 还是对外隐藏了很多比较关键的设计，比如如何支持状态服务，网络和存储方面有没有什么特殊的设计，master 的设计细节等等都没有展开。不过很多其他设计的细节都在工作中碰到了，很多细节都很有现实意义。当然读到最后我觉得 Google 放出来就是像推广他的 k8s 项目。


