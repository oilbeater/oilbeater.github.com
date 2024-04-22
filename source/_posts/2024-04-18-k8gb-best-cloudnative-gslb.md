---
title: "k8gb: 云原生最佳开源 GSLB 方案" 
date: 2024-04-18 10:01:10
tags: [kubernetes, network]
---

如何将流量在多个 Kubernetes 集群之间进行负载均衡，并做到自动的灾备切换一直是一个让人头疼的问题。我们之前调研了公有云，[Karmada Ingress](https://github.com/karmada-io/multi-cluster-ingress-nginx)，自己也做了一些手动 DNS 的方案，但这些方案在成本，通用性，灵活度以及自动化程度上都有所欠缺。直到调研到了 [k8gb](https://www.k8gb.io/) 这个由南非银行 [Absa Group](https://www.absa.africa/) 为了做金融级别的多活而启动的一个项目。k8gb 巧妙的利用了 DNS 的各种协议完成了一个通用且高度自动化的 GSLB 方案，看完后我就再也不想用其他的方案了。这篇博客会简单介绍一下其他几个方案各自存在的问题，以及 k8gb 究竟是如何巧妙的利用 DNS 来实现的 GSLB。

## 什么是 GSLB

GSLB（Global Service Load Balancer）是相对于单集群负载均衡的一个概念，单集群负载均衡主要作为一个集群的入口将流量分发到集群内部，而 GSLB 通常作为再上一层多个集群的流量入口，进行流量负载均衡和故障处理。一方面 GSLB 可以设置一些地理亲和的规则达到流量就近转发提升整体的性能，另一方面当某个集群出现问题后可以自动将流量切换到正常集群，减少单个集群故障对用户的影响。

## 其他方案的问题

### 商用负载均衡

GSLB 并不是一个新出的概念，所以不少商业公司都在这方面有很成熟的产品，例如 [F5 GSLB](https://www.f5.com/solutions/use-cases/global-server-load-balancing-gslb)。这类产品通常有以下几个缺点：

1. 没有很好的和云原生对接，通常需要在 Kubernetes 集群外独立部署专有的软硬件，无法做到统一管理。
2. 成本高，且有厂商锁定的风险。

### 公有云全局负载均衡

公有云为了解决流量多地域分发会提供多集群负载均衡的产品，例如 AWS 的 [Global Accelerator](https://aws.amazon.com/global-accelerator/) 和 GCP 的 [External Application Load Balancer](https://cloud.google.com/load-balancing/docs/https)。GCP 上甚至还有一组自定义的 [Multi Cluster Ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-ingress) 资源，可以很好的和 Kubernetes 里的 Ingress 进行对接。但是他们也有一下几个问题：

1. 虽然是多集群负载均衡，但是多个集群必须是同一个公有云，不能在多云间进行流量调度。
2. 私有云无法使用这个方案。

### Karmada Multi  Cluster Ingress

Karmada 是一个多集群的编排工具，也提供了自己的多集群流量调度方案 [Karmada Multi Cluster Ingress](https://karmada.io/docs/userguide/service/multi-cluster-ingress/)。该方案通过在某个集群内部署一个由 Karmada 社区提供的 ingress-nginx 以及定义 `MultiClusterIngress` 来完成多集群流量调度，但这个方案有以下几个问题：

1. 依赖多集群间容器网络打通，和 ServiceImporter ServiceExporter 等 CRD，整体要求比较高。
2. 需要额外再去管理这个提供 GSLB 服务的 ingress-nginx 实例，该部署在哪，该部署多少，怎么分配都是运维期间需要考虑的问题。
3. 这个社区改造后的 [multi-cluster-ingress-nginx](https://github.com/karmada-io/multi-cluster-ingress-nginx) 近两年基本没有什么代码提交，是否可用会让人有担忧。

### 简单的 DNS 方案

如果手动攒出来一个简单的基于 DNS 的方案其实也是可以的，大部分 DNS 厂商都提供了健康检查的功能，因此我们可以将多个集群的出口 IP 地址加入到 DNS 的解析记录里，同时配置健康检查来做故障切换。但是这个简单的方案在规模扩大后就会有一些明显的限制：

1. 无法很好的自动化，一个集群下可能有多个不同的域名和多个不同的 Ingress IP 的组合，手动去管理他们的映射关系会随着规模增加变得难以维护。
2. DNS 厂商的健康检查通常是基于 TCP 和 ICMP 的，因此如果一个集群的出口完全挂掉这种故障是可以检测到并进行切换的。但是如果是局部故障就无法探测，例如多个 Ingress 复用一个 ingress-controller 并通过域名进行流量转发的情况下，如果其中一个服务的后端实例全部异常了，但是 ingress-controller 上的其他服务正常，那么健康检查还是会正常通过，并没有办法把流量切换到另一个集群。
3. DNS 本身存在各级缓存，更新时间可能较长。
4. DNS 健康检查本身也是个厂商提供的能力，并不能保证所有厂商都能提供这个能力，尤其是在私有云的场景。

## k8gb 的解决方案

k8gb 的解决方案其实也是用 DNS，但是通过自己的一系列巧妙的设计，解决了上面提到的简单 DNS 方案的一系列缺陷。

简单 DNS 方案的问题本质是没有和 Kubernetes 进行很好的对接，Kubernetes 内的一些动态信息，例如新增的 Ingress，新增的域名，服务的健康状态没法很好的同步到上游 DNS 服务器，而上游 DNS 服务器简单的健康检查也没办法应付 Kubernetes 里这种复杂的变化。因此 k8gb 最核心的一个变化就是上游的 DNS 记录不再是通过 A 记录或者 AAAA 记录指向集群的一个出口地址，而是 forward 到集群内的一个自己配置的 CoreDNS 进行 DNS 解析，将真正复杂的 DNS 逻辑下沉到集群里来自己控制。这样上游 DNS 只需要做简单的代理，不再需要配置健康检查，也不再需要动态的调整多个地址映射。

调整后用户请求 DNS 的流程如下图所示：

- ![K8GB multi-cluster interoperability](https://www.k8gb.io/docs/images/gslb-basic-multi-cluster.svg)

1. 用户向外部 DNS 服务商请求一个域名的 IP 记录。
2. 外部 DNS 将这个请求代理发送给集群内由 k8gb 管控的一个 CoreDNS。
3. k8gb 根据 Ingress Spec 里的域名，Ingress Status 里的 Ingress IP 以及集群内对应后端 Pod 的健康状态，负载均衡策略等信息分析出一个可用的 Ingress IP 返回给用户。
4. 用户通过这个 IP 就可以直接访问到对应的 Ingress Controller。
5. 当某一个集群的 k8gb 管控的 CoreDNS 出问题时由于上游 DNS 会同时将 DNS 请求代理到多个集群，另一个集群也可以返回自己的 Ingress IP，用户端可以通过多个返回的可用 IP 选择一个进行访问。

这种方式管理员只需要在上游 DNS 注册几个域名后缀并代理到每个集群的 CoreDNS 就可以了，k8gb 本身也提供了自动化的能力，只要配好证书可以自动分析 Ingress 内使用的域名自动注册给上游 DNS，大幅简化了管理员的操作。

整个流程中还有一个特殊的点要注意，就是每个集群自己的 CoreDNS 不能只记录本集群 Ingress IP 的地址，还需要记录其他集群同一个 Ingress 的 Ingress IP 地址。因为如果只记录本集群的，当本集群对应服务的 Pod 都 Not Ready 时，CoreDNS 会返回 NXDomain 如果客户端收到了这个返回就会按照域名无法解析处理，此时另一个集群服务其实是可以正常提供服务的。因此 k8gb 还需要同步所有集群同一个域名 Ingress 对应的 Ingress IP 和它的健康状态。

众所周知多集群之间的数据同步也是一个世界难题，但是 k8gb 同样通过 DNS 巧妙的实现了数据的同步。

同步的流程图如下所示：

![k8gb multi-cluster-interoperability](https://www.k8gb.io/docs/images/k8gb-multi-cluster-interoperabililty.svg)

大致的思路是每个集群的 k8gb 会把自己的 CoreDNS 的 Ingress IP 同样注册到上游 CoreDNS，这样每个集群就可以直接访问另一个集群的 CoreDNS 了。然后每个集群内的 CoreDNS 再按照一个特殊的域名格式比如 `localtargets-app.cloud.example.com` 来保存本集群内 `app.cloud.example.com` Ingress 的 Ingress IP 并维护其健康状态。这样每个集群就都可以通过这个特殊的域名来或者其他集群这个域名对应的 Ingress IP 然后加入到自己的返回结果里，实现了域名解析的多集群同步。

## 总结

k8gb 作为一款开源的 GSLB 实现了和 Kubernetes 的无缝对接，能够很好的对跨集群的域名和流量进行自动化管理，并且对外部的依赖降到了只需要一个添加 DNS 记录的 API，真正实现了一套可以多云统一的 GSLB 方案。尽管目前这个项目还没有那么火热，但在我心里它已经是这个领域内的最佳方案了。