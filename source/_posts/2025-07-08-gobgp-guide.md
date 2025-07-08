---
title: GoBGP 快速上手
date: 2025-07-08 22:48
created:
  - 2025-07-08
tags:
  - gobgp
  - tutorial
  - networking
---
在做 MetalLB 和 Calico 的一些测试时需要验证 BGP 相关的功能，然而每次测试要去联系运维团队配合网络变更是不太现实的，并且大多数情况我们只要验证 BGP 信息正常交换就可以了，不需要真的去改变物理网络。于是就找到了 [GoBGP](https://github.com/osrg/gobgp) 这个软件路由器进行模拟。

GoBGP 本身有着很复杂的配置，但是如果你只是像我一样只是想有个虚拟的路由器，让客户端把 BGP 信息发送过来，检查路由表信息是否正确更新，那看这篇文章就可以了。

## 下载 GoBGP 二进制文件

去 [Release](https://github.com/osrg/gobgp/releases) 制品列表里找到对应系统的制品解压即可，重要的只有两个二进制文件： `gobgpd` 虚拟路由器进程，`gobgp`命令行工具，用来查看路由对不对。

## 启动虚拟路由器

创建一个 `gobgp.toml` 文件，最简单的配置就照着我下面这个就好了，大部分基础的云原生领域 BGP 相关的软件测试用这个就够了。

```toml
[global.config]
  as = 65000                          # 测试环境随便写一个就好
  router-id = "10.0.0.1"              # 测试环境随便写一个就好，写 GoBGP 所在节点 IP 日志清晰一些

[[dynamic-neighbors]]                 # 被动连接模式，省去了配固定客户端
  [dynamic-neighbors.config]
    prefix     = "192.168.0.0/24"     # 允许哪个 IP 范围内的客户端来连接 
    peer-group = "ext-ebgp"

[[peer-groups]]                       # 复制粘贴就好了
  [peer-groups.config]
    peer-group-name = "ext-ebgp"
    peer-as         = 65000
  [[peer-groups.afi-safis]]
    [peer-groups.afi-safis.config]
      afi-safi-name = "ipv4-unicast"
```

启动 `gobgpd`

```shell
./gobgpd -f gobgp.toml
```

在另一个终端观察当前的路由表

```shell
./gobgp global rib
```

这样基本上 MetalLB，Calico 的基础 BGP 能力就可以测试了。如果想更配更复杂的模式，比如 [Router Reflector](https://github.com/osrg/gobgp/blob/master/docs/sources/route-reflector.md)，[EVPN](https://github.com/osrg/gobgp/blob/master/docs/sources/evpn.md) 那就再去翻 [GoBGP 的文档](https://github.com/osrg/gobgp?tab=readme-ov-file#documentation)吧。