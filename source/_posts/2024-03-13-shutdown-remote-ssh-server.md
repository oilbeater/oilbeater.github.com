---
title: 自动关闭 VS Code Remote SSH 机器
date: 2024-03-13 10:09:26
tags: [vscode, tools, docker]
---

我现在所有的开发环境都转移到了 GCP 的 Spot Instance 实例，然后用 VS Code Remote SSH 插件进行连接。这种方式的好处是 GCP 可以按秒计费，即使开了很高规格的机器只要及时关机费用也是可控的，缺点是如果中间忘了关机赶上过节那费用就烧开了。再被烧掉了 10 多美元后，痛定思痛决定找个能在 VS Code 空闲时自动关机的方法。过程中为了能够在 Docker 容器内执行 shutdown 命令还搞了一些黑魔法。

# 如何判断空闲

这个功能其实类似 CodeSpace 里的 idle timeout，但是 Remote SSH 这个插件并没有暴露这个功能，所以只能自己实现。其实主要的难点在于如何在 Server 端判断空闲，找了一圈没在 VS Code 里看到有暴露的接口，于是就想能不能跳出 VS Code 看看有什么方法能够简洁的判断空闲发生。

最直接的想法就是去看 SSH 的连接，因为 Remote SSH 也是通过 SSH 连接上来的，如果当前机器没有存活的 SSH 连接，那么就可以认为是空闲直接关机了。但是问题是 Remote SSH 的连接超时时间会特别长，搜索了一些 Issue 有说是 4 个小时的，我也尝试了直接关闭 VS Code 的客户端，发现 Server 端的 SSH 连接也一直没有消失。如果在 Server 端设置 SSH 超时，Client 那边很快就会重连，连接数量也不会减少。

既然没法通过直接看 SSH 连接数量来判断，那么就进一步去看能不能判断已有的 SSH 连接是不是已经没有流量了。用 `tcpdump` 抓包看了一下，即使客户端没有任何交互，还是会有 1s 一次的 TCP 心跳数据包，所以也不能有流量为 0 来判断。不过观察下来心跳数据包的大小都是固定的，都是 44 字节，正好可以根据这个特征来判断，如果一段时间内 SSH 端口没有大于 44 字节的数据包就可以判断空闲了。

于是第一版本的脚本就出来了：

```bash
#!/bin/bash

while true; do
  if [ -f /root/dump ]; then
    rm /root/dump
  fi

  timeout 1m tcpdump -nn -i ens4 tcp and port 22 and greater 50 -w /root/dump

  line_count=$(wc -l < /root/dump)

  if [ $line_count -gt 0 ]; then
    rm /root/dump
  else
    rm /root/dump
    shutdown -h now
  fi
done
```

这样就实现了 1 分钟内 SSH 端口没有非心跳数据包就关机的功能，下一步就是要让这个脚本自动运行了。

# Docker 黑魔法

在把脚本打包成 Docker 镜像时发现了一个有趣的问题，那就是所有的 Base Image 里都没有 `shutdown` 命令，`shutdown` 命令也没法很容易的安装。为了能够执行主机上的 `shutdown` 命令，就需要在 Docker 容器里切换到主机的命名空间，再去关机。所以需要把之前的脚本稍微修改一下，包装一下 `shutdown` 命令：

```bash
nsenter -a -t 1 shutdown -h now
```

这个 `nsenter` 命令的作用是选定 Pid 为 1 的进程，然后进入这个进程的所有(pid, mount, network) Namespaces，这样当 Docker 运行在共享主机 Pid 模式下我们相当于就进入了主机 1 号进程的所有 Namespaces，看上去就和 SSH 到主机上一样可以执行操作了。这样只要再用下面的命令启动容器，就可以不担心忘记随时关机了：

```bash
docker run --name=close --pid=host --network=host --privileged --restart=always -d close:v0.0.1
```

# 总结

通过监控 SSH 的流量情况可以一定程度上猜测 VS Code 已经空闲了，然后再用 Docker 的一些黑魔法就可以实现自动关机了。不过整个链路的黑魔法都太多了，有没有什么简单的方式呢？