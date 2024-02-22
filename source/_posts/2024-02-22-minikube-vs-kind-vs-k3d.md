---
title: minikube，kind 和 k3d 大比拼
date: 2024-02-22 14:42:22
tags: [kubernetes, ci]
---

作为云原生生态的一个开发者，开发中经常碰到的一个需求是要频繁测试应用在 Kubernetes 环境下的运行状态，在 CI 中可能还要快速测试多个不同 Kubernetes 集群的配置，例如单点，高可用，双栈，多集群等等。因此能够低成本的在本地单机环境快速创建管理 Kubernetes 集群就成了一个刚需。本文将介绍几个常见的单机 Kubernetes 管理工具 minikube, kind 和 k3d 各自的特点、使用场景以及可能的坑。

> TL;DR
> 如果你只关心快不快，那么 k3d 是最好的选择。如果你关心的是兼容性以及测试尽可能模拟真实场景，那么 minikube 是最稳妥的选择。kind 算是在这两个之间的一个平衡。

- [技术路线比较](#技术路线比较)
  - [minikube](#minikube)
  - [kind](#kind)
  - [k3d](#k3d)
- [启动性能比较](#启动性能比较)
  - [测试方法](#测试方法)
  - [测试结果](#测试结果)
- [总结](#总结)


# 技术路线比较

这三者大体功能是类似的，都能够完成单机管理 Kubernetes 的任务，但是由于一些历史原因和技术选项导致了一些细节和使用场景的差异。

## minikube

[minikube](https://minikube.sigs.k8s.io/docs/) 是 Kubernetes 社区最早的一款快速在本地创建 Kubernetes 的软件，也是很多老人第一次上手 Kubernetes 的工具。早期版本是通过在本机创建 VM 来模拟多节点集群，这个方案的好处是能够最大程度还原真实场景，一些操作系统级别的变化，例如不同 OS，不同内核模块都可以覆盖到。缺点就是资源消耗太大，而且在一些虚拟化环境如果没有嵌套虚拟化的支持是没办法运行的，并且启动的速度也比较慢。不过社区最近也推出了 Docker 的 Driver 这些问题都得到了比较好的解决，不过对应代价就是一些虚拟机级别的模拟就不好做了。此外 minikube 还提供了不少的 addon，比如 dashboard，nginx-ingress 等常见的社区组件都能快速的安装使用。

## kind

[kind](https://kind.sigs.k8s.io/) 是近几年流行起来的一个本地部署 Kubernetes 的工具，他的主要特点就是用 Docker 容器模拟节点，并且基本只专注在 Kubernetes 标准部署这一个事情上，其他社区组件都需要额外自己去安装。优点就是启动速度很快，熟悉 Docker 的人用起来也很顺手。缺点是用了容器模拟缺乏操作系统级别的隔离，而且和宿主机共享内核，一些操作系统相关的测试就不好测试了。我之前在测一个内核模块的时候就因为宿主机加了一些 netfilter 功能，结果 kind 里的 Kubernetes 集群挂了。

## k3d

[k3d](https://k3d.io/stable/) 是一个超轻量的本地部署 Kubernetes 工具，他的大体思路和 kind 类似，都是通过 Docker 来模拟节点，主要区别在于部署的不是个标准 Kubernetes 而是一个轻量级的 [k3s](https://k3s.io/)，所以他的大部分优缺点也来自于下面这个 k3s。优点就是安装极致的快，你先别管对不对，你就问快不快吧。缺点主要来自于为了速度做出的一些牺牲，比如镜像用的是个超精简的操作系统，连 glibc 都没有，因此一些要在操作系统层面的操作都会无比困难。还有就是他的安装方式和常见的 kubeadm 也不一样，Kubernetes 组件都不是容器启动的，如果依赖标准部署的一些特性可能都会比较困难。

# 启动性能比较

minikube 社区有一些[性能测试报告](https://minikube.sigs.k8s.io/docs/benchmarks/timetok8s/v1.32.0/)，正好对比的就是本文关注的三款软件的启动速度，不过我更关注的是其他的一些方面，比如镜像大小，内存占用以及最小化安装的启动时间，所以还是再做了一组测试。

## 测试方法

由于三款软件都是一行命令就可以启动，测试还是比较方便的，主要注意以下几个点：

1. minikube 采用 Docker Driver，因为真要测启动速度还用虚拟机的 Driver 就没什么意义了。
2. 所有测试都是镜像已经下载到本地的结果，不会涉及网络下载时间。
3. 都只启动最基本的组件，不安装其他插件，但是基础 CNI 和 CoreDNS 以及 CSI 都是有的，保证应用的基本运行。
4. 使用 `docker image` 命令查看镜像大小，使用 `docker stat` 查看内存用量。

测试的命令如下：

```bash
#minikube
time minikube start --driver=docker --force

#kind
time kind create cluster

#k3d
time k3d cluster create mycluster --k3s-arg '--disable=traefik,metrics-server@server:*' --no-lb
```

## 测试结果

| 名称 | 软件版本 | Kubernetes 版本 | 镜像大小 | 启动时间 | 内存消耗 |
| -------- | -------- | -------- | ---- | ---- | ---- |
| minikube   | v1.32.0 | v1.28.3 | 1.2GB | 29s | 536MiB |
| kind   | v0.22 | v1.29.2 | 956MB | 20s | 463MiB |
| k3d   | v5.6.0 | v1.27.4 | 263MB | 7s | 423MiB |

可见单从启动性能这个指标，k3d 在镜像大小，启动时间和内存消耗几个方面都有比较大的优势，对于用 Github 免费 Action 跑 CI 的穷人还是很有吸引力的。

# 总结

如果快和更少的资源占用是最重要的目标，那么 k3d 相当合适，如果要测试需要操作系统级别隔离的功能，那么 minikube 的虚拟机 Driver 是唯一的选择，其他场景下 kind 会在兼容和性能之间比较平衡。