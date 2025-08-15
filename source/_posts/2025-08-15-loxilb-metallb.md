---
title: LoxiLB -- More than MetalLB
date: 2025-08-15 14:48
created:
  - 2025-08-15
tags:
  - metallb
  - loxilb
---
[MetalLB](https://github.com/metallb/metallb) 目前几乎成了私有云场景下 Kubernetes 提供 LoadBalancer 类型 Service 的事实标准。他的实现逻辑简单清晰，并且功能单一，基于 Gossip 的分布式选主也保证了 VIP 的漂移可以做到迅速且不依赖 Kubernetes 的状态。但是它在专注的情况下也缺少了一些在生产环境极为重要的功能，这也是为什么我最近在调研其他的开源项目，并发现了 [LoxiLB](https://github.com/loxilb-io/loxilb) 这个很不错的 MetalLB 替代项目。

## MetalLB 的缺陷

MetalLB 虽有 LB 之名，但实际上并不处理任何转发平面的工作。严格来说它只提供了 VIP 的对外通告能力，所有转发平面的事情都是依赖 kube-proxy 或者各类的 kube-proxy 的替代 来实现。这样的好处是它可以专注在提供各种类型的 VIP 宣告方式，并且能和 Kubernetes 本身的行为保持最大的兼容性，但同时由于 kube-proxy 本身孱弱的能力，也限制了 MetalLB 本身的功能。

### 缺乏主动健康检查

这是 Kubernetes 由来已久的一个问题，Service 后端的 Endpoint 健康状态依赖 Pod 本身的 ReadinessProbe/LivenessProbe，Probe 的执行依赖当前节点的 kubelet。造成的结果就是断电或类似的直接宕机情况下 kubelet 无法更新 Pod 的健康状态，需要等到触发 node not ready 的超时才会修改 Pod 监控状态，通常在大集群这个超时可能会有数分钟，导致这段时间内访问 Service 会出现失败。

严格来说这并不是 MetalLB 的问题，但是由于 MetalLB 本身对数据转发平面没有任何控制能力，无法主动探测 Pod 真实健康情况也无法修改 Pod 健康状态，只能被动接受这种机制。

虽然通过 [Pod ReadinessGates](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-readiness-gate) 可以使用额外的 controller 主动探测来控制 Pod 健康状态，间接解决这个问题，但对于 MetalLB 来说这个也和它没有什么关系，并没有能开箱即用的方案，这对生产环境还是个很大的隐患。

### 缺乏有效的监控

这同样是依赖 kube-proxy 实现导致的一个问题，kube-proxy 的多种实现方式都没有流量层面的监控，导致的后果就是如果你看 MetalLB 提供的[监控指标](https://metallb.universe.tf/prometheus-metrics/)就会发现里面没有任何流量的指标。这种几乎没有任何数据平面监控的 LB 要上生产，就有点过于松弛了。

## LoxiLB 的改进

LoxiLB 本身是一个为电信场景的特殊需求，使用 eBPF 打造的专用 LB，它完全实现了控制平面和数据平面是一个完整的 LB 实现。LoxiLB 本身的功能十分多，尤其在 SCTP 领域有十分多专属能力，这里不赘述只是重点看一下针对 MetalLB 缺陷的补足。

### 主动健康检查

LoxiLB 可以给每个 Service 配置[主动健康检查](https://docs.loxilb.io/latest/cmd/#create-end-point-for-health-probing)，支持 ping, tcp, udp, sctp, http, https 也支持超时，重试之类的细粒度配置，虽然称不上多优秀，但 MetalLB 就是没有这个功能，这就显得很尴尬。

### 监控指标

这一点就是 eBPF 的强项了，LoxiLB 内置了不少 [Metrics 和 Grafana 面板](https://docs.loxilb.io/latest/loxilb-incluster-grafana/)，此外由于数据平面是自己实现的，添加各类监控指标也相对容易一些。

### 潜在的风险

整体来看 LoxiLB 是一个我很喜欢的项目，甚至很多关于 SCTP 协议的理解我都是看了它的一些配置才能理解是怎么回事。但是他还是有着一些不足的地方：

- 选主的逻辑目前还是 Kubernetes 那套 Leader Election 逻辑，但我更喜欢 MetalLB 那种与 Kubernetes 解耦的选主逻辑。
- 文档整体比较凌乱，虽然文档内容很多但是组织的不是很好，好多配置得靠搜索才能找到，一些文档格式也存在问题。
- 虽然该项目是 CNCF 沙箱项目，但是整体的活跃度和参与度还是偏低，能感觉出来该项目应该还是个比较成熟的内部项目拿了出来，但是如果社区采用度比较低的话未来还是有些隐患。

## 小结

MetalLB 依然是一个我很喜欢的项目，它极其精准地解决了 VIP 宣告及高可用的问题，但是如果达到生产上完备的状态还需要配合其他组件。LoxiLB 则是一套完整的 LB 解决方案，但是社区的发展还处于早期，还有待更多人的参与。