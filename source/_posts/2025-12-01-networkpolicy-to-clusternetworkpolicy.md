---
title: 从 NetworkPolicy 到 ClusterNetworkPolicy
date: 2025-11-30 09:45
created:
  - 2025-11-30
tags:
  - opensource
  - network
---
[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) 作为 Kubernetes 早期的 API 看似美好，实际使用过程中就会发现它功能有限，不易扩展，不易理解且不易使用。因此 Kubernetes 成立了 [Network Policy API Working Group](https://network-policy-api.sigs.k8s.io/) 来制订下一代的 API 规范，而 [ClusterNetworkPolicy](https://network-policy-api.sigs.k8s.io/api-overview/#the-clusternetworkpolicy-resource) 就是目前探讨出来的最新成果，未来可能会成为新的规范。

## NetworkPolicy 的局限性

NetworkPolicy 是 Namespace 级资源，本质上是“应用视角”的策略。它通过 podSelector、namespaceSelector 来选中一批 Pod，然后对这些 Pod 的 Ingress、Egress 做限制。这带来了几个实际的问题：
### 缺少 Cluster 级别的控制

由于策略的作用域是 Namespace，集群管理员无法定义集群级别的默认网络策略，只能在每个 Namespace 里都创建相同的网络策略。这样一方面每次更新策略需要对所有 Namespace 下的资源进行更新，另一方面，很容易和开发者创建的网络策略产生冲突。管理员设置的策略，应用侧很容易就可以通过新的策略绕过去。

本质上在于 NetworkPolicy 这种应用视角的策略和管理员集群视角的策略存在冲突，当用户的安全模型并不是应用视角的时候 NetworkPolicy 就会变得难以应用。而集群管理员管控集群整体的安全策略是个现实中很常见的场景。

### 语义不清晰

NetworkPolicy 的语义有几个“坑”，新手和运维人员都容易踩：

- 隐式隔离。  
    一旦有任何 NetworkPolicy 选中了某个 Pod，那么“未被允许”的流量就会被默认拒绝。这种隐式的行为需要靠心算来推导，很难一眼看懂。
    
- 只有允许，没有显式拒绝。  
    标准 NetworkPolicy 只能写 allow 类型的规则，想要“拒绝某个来源”，通常要通过补充其他 allow 规则间接实现，或者依赖某些 CNI 厂商特有的扩展。
    
- 没有优先级。  
    多个 NetworkPolicy 选择同一批 Pod 时，规则是加法而不是覆盖关系。最终行为往往需要把所有策略合在一起看，排查问题时非常困难。

这些特点叠加在一起，就会导致 NetworkPolicy 理解起来困难，调试起来更困难。

## ClusterNetworkPolicy 的解决方案

为了解决 NetworkPolicy 固有的问题，Network Policy API 工作组提出了一个新的 API —— ClusterNetworkPolicy (CNP)，它的目标是在不破坏现有 NetworkPolicy 用法的前提下，给集群管理员提供一个更清晰、更强大的网络控制能力。

其最核心的思路是引入策略分层，在现有的 NetworkPolicy 之前和之后分别引入独立的策略层，将集群管理员的策略和应用的策略分开，提供了更丰富的视角和更灵活的使用。

![](../images/20251201104247.png)

一个示例如下：

```yaml
apiVersion: policy.networking.k8s.io/v1alpha2
kind: ClusterNetworkPolicy
metadata:
  name: sensitive-ns-deny-from-others
spec:
  tier: Admin
  priority: 10
  subject:
    namespaces:
      matchLabels:
        kubernetes.io/metadata.name: sensitive-ns
  ingress:
    - action: Deny
      from:
        - namespaces:
            matchLabels: {} 
      name: deny-all-from-other-namespaces
```


### 集群管理员视角

新引入的 ClusterNetworkPolicy 是集群级别资源，管理员可以直接选中多个 Namespace 下的 Pod 进行策略控制。同时 Admin Tier 的策略可以先于 NetworkPolicy 生效，这样集群管理员只需要少量的 Admin Tier 策略就可以控制住整个集群的红线行为。

而 Baseline Tier 的策略在所有 NetworkPolicy 都不匹配后执行，相当于提供了一个兜底策略。

简单来说：
- `tier: Admin` 的策略用来定义**绝对不能做**的事情。
- `tier: Baseline` 的策略用来定义**默认不建议做**的事情，用户可以通过 NetworkPolicy 来放行。

### 明确的优先级

ClusterNetworkPolicy 中新增了 `priority` 字段，这样在同一个 Tier 中多个规则的范围出现重叠时，可以通过优先级清晰的界定哪个规则该生效，不会再出现 NetworkPolicy 里那种隐式覆盖，需要互相猜测的情况。

### 清晰的动作语义：Accept / Deny / Pass

和 NetworkPolicy 只有“允许”语义不同，ClusterNetworkPolicy 的每条规则都有一个显式的 `action` 字段，可以取值：

- `Accept`：允许这条规则选中的流量，并停止后续策略评估
- `Deny`：拒绝这条规则选中的流量，并停止后续策略评估
- `Pass`：在当前 tier 里跳过后续 ClusterNetworkPolicy，交给下一层继续评估

同时，文档中特别强调：
- ClusterNetworkPolicy 不再有 NetworkPolicy 那种“隐式隔离”的效果
- 所有行为都来自你写的规则本身，读策略时看到什么就是什么

结合优先级的配置，规则的理解就不再会产生模糊的情况，理解上也变得不那么困难。

## 小结

ClusterNetworkPolicy 一定程度上回归了传统的分层网络策略的架构，在解决了 NetworkPolicy 问题的情况下没有带来破坏性的变化，可以说是一个很不错的设计，希望能尽快看到这个规范的成熟和落地。
