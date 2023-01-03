---
layout:	post
title:	"Linux 系统性能分析工具图解读(一)"
date:	2014-09-08 14:19:55
tags:
- 技术
- linux
- 性能
---

最近看了 Brendan Gregg 大神著名的 Linux Performance Observability Tools，这么好的资料不好好学习一下实在是浪费了，又找到了大神的[ ppt 和 演讲](http://www.brendangregg.com/linuxperf.html)（需爬墙），于是把相关的命令和概念连预习，学习，复习走了一遍。

 ![](http://oilbeater.qiniudn.com/linux_observability_tools.png)

首先学习的是大神提出的 Basic Tool 有如下几个：

- uptime

- top （htop）

- mpstat

- iostat

- vmstat

- free

- ping

- nicstat

- dstat

## uptime ##

uptime 比较重要的能显示当前系统的负载状态，但是这个负载究竟是什么意思呢？查了一些资料负载指的是当前可运行的程序加上正在运行的程序再加上等待 IO 的程序，比如现在运行着一个，一个等待运行，还有一个等待 IO 那么负载就是3. uptime 后面三个数分别是 1min， 5min 和 15min 的负载平均值，由于内核用了一个指数平滑的平均算法，这个值不能直接反应当前等待的进程数。此外这个值没对多核进行 normalization 所以单核情况下当负载是 1 的时候说明 cpu 满载了，但是对于 4 核 cpu 刚到满负载的 25%。 一般情况下这个值越大就说明等待 CPU 的进程越多，如果大于核数就说明有进程在等待 CPU，需要看一下程序的问题或者考虑加机器了。另外即使负载过载了也不一定说明 CPU 的利用率高，因为很可能是大量的请求 IO 的进程在等待，像一些数据库服务，所以看完负载后还要针对应用场景综合考量。


## top & htop##

top 其实是一个相当全面的分析了还是事实的，其他很多命令能拿到的数据，top 一个命令就可以拿到。但是他的一个问题就是本身的 overhead 比较大，如果系统负载本身就很大那么可能就会卡住了。此外 top 可能会忽视掉那些生命周期很短的程序。top 的 manual 里详细介绍了每个指标的意义，翻看一下还是很有收获的。其中比较要关注的有 wa（io wait）,查看是不是你的 IO 是瓶颈，还有 st (time stolen from this vm by the hypervisor) 这个指标会出现在虚拟机里的系统中，表示的是你的虚拟机在等待真实物理机的 CPU 资源的时间。如果这个值很高的话说明你的服务提供商的 CPU 资源有限你没抢过别人，很有可能使服务商超卖了。碰到这种情况要么打客服投诉，或者多掏点银子找个靠谱的运营商吧。

htop 是 top 的改进版，带着各种颜色表示和百分比进度条，以及更丰富的功能，小伙伴们可以尝试一下。


## mpstat ##

mpstat 可以显示出每个 CPU 核心的工作情况，其实也可以在 top 里输入 1 看到。通过这个命令我们可以观察是不是存在负载不均的现象，某个核心跑满了，另一个还在闲着，造成整体性能的下降。 


## iostat ##

加上 -x 参数后可以看到几乎全部的 io 指标，包括 tps， 请求 queue 的平均长度，平均处理时间， 磁盘带宽利用率等等。每个指标 manual 中都有详细的解释。

## vmstat & free ##

vmstat 是一个展示内存整体使用情况的命令，其中要关注一下 swpd 和 swap 的 in/out 。如果这一部分的数值过大，会频繁的 IO 造成性能下降，要么看看是不是程序内存泄露了，要么就加内存吧。 memory 里的 buffer 指的是写磁盘缓冲区， 而 cache 可以当成是读文件的缓冲区。free也是类似的功能，不过只展示内存部分的内容。

## ping ##

这个相对来说简单一些，主要反映了主机间的延迟和连通性，很多时候也只能告诉我们这些了。可以尝试一下 hping 有着指定端口，高级 tracerout 的功能。

## nicstat ##

一个和 iostat 类似，不过是针对网卡的命令。

## dstat ##

一个综合了cpu、 memory、 IO、 network 的工具，可以事实展示当前的系统资源利用情况。

以上就是最基础的命令了，高级一些的命令有：

- sar

- netstat

- pidstat

- strace

- tcpdump

- blktrace

- iotop

- slabtop

- sysctl

- /proc

等我研究研究再写总结。
