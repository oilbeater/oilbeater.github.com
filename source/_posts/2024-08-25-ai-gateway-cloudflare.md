---
title: AI Gateway 调研之 Cloudflare AI Gateway
date: 2024-08-25 14:10:45
tags:
    - AI
    - Gateway
    - Cloudflare
---

随着 AI 的火热，眼看着之前调研的各家竞品 API 网关产品纷纷把自己的介绍改为 AI Gateway，于是就想调研一下这些所谓的 AI Gateway 究竟做了些啥。这次调研的对象有一些之前靠 API 网管或者云原生 Ingress Controller 起家加入 AI 功能的，例如：[Kong](https://konghq.com/products/kong-ai-gateway)，[Gloo](https://www.solo.io/products/gloo-ai-gateway/) 和 [Higress](https://higress.io/en/)。也包括一些第一天就是借着 AI 起来的我认为真正 AI 原生的网关，例如 [Portkey](https://portkey.ai/features/ai-gateway) 和 [OneAPI](https://github.com/songquanpeng/one-api)。以及这篇博客介绍的基于公有云 Serverless 的 [Cloudflare AI Gateway](https://developers.cloudflare.com/ai-gateway/)。

大体来看目前的 AI Gateway 主要能力在三个方面：

**常规 API 网关功能在 AI API 上的应用**，例如：监控，日志，限速，反向代理，请求或响应改写，集成用户系统等。这些功能其实和 AI 关系不大就是把 LLM 的 API 当成了一个普通的 API 进行接入。

**部分 API 网关功能针对 AI 进行优化**，例如限速功能增加基于 Token 的限速，缓存功能增加基于 Prompt 的缓存，防火墙基于 prompt 和 LLM 返回进行过滤，多个 LLM API Key 之间的负载均衡，多个 LLM Provider 的 API 转换。这些功能在原有的 API 网关就存在类似的概念，不过在 AI 场景下又有了相应的扩展。

**基于 AI 应用的场景增加的新功能**，例如部分 AI 网关增加了 Embedding 和 RAG 的功能，把向量数据库和文本数据库的功能通过 API 的形式提供出来。还有一些针对 token 用量的性能优化，比如 Prompt 简化，语义化 Cache 等。还有一些更偏应用层的功能，例如对 LLM Output 提供打分功能等。

这篇博客介绍 [Cloudflare AI Gateway](https://developers.cloudflare.com/ai-gateway/) 这款 AI Gateway 的特点。

# 基本原理

Cloudflare 的这款 AI Gateway 主要功能其实就是一个反向代理，看完了我甚至觉得我用 Cloudflare Worker 捣鼓一阵也能做个功能类似的。如果你原来用的是 OpenAI 的 API 那么现在你要做的就是把 SDK 里的 baseURL 换成 `https://gateway.ai.cloudflare.com/v1/${accountId}/${gatewayId}/openai` 就可以了。在这个过程中由于流量进出都是过 Cloudflare 的，Cloudflare 平台上就可以提供对应的监控，日志，缓存等功能。

这个方案有下面几个优点：
- 接入很简单，改一下 baseURL 就接入进来了，API 格式也没有任何变化。并且完全是 Serverless 的，不需要自己额外管理任何服务器，这个功能现在是免费的，直接就白嫖了监控数据。
- 借助 Cloudflare 的全球网络可以实现一定的用户接入加速，不过这个用户接入的加速相比 LLM 本身的延迟比重应该很小，顶多在首个 Token 的延迟会有明显变化。
- 通用借助 Cloudflare 的全球网络可以一定程度隐藏掉源 IP，对于一些 OpenAI API 访问受限的区域用这个可以绕过去。

但对应的也有下面的缺点：
- 所有请求信息包括 API Key 都要在 Cloudflare 上过一道，会有安全方面的一些隐患。
- Gateway 本身没有什么插件机制，想扩展功能的话会比较麻烦，只能在外面再套一层。
- 同样是因为 Cloudflare 的全球网路欧，如果一个 Key 一直变换 IP 地址访问，不知道会不会触发 OpenAI 那边的拉黑。 

# 主要能力

## 多个 Provider 支持

由于 Cloudflare AI Gateway 并没有对 LLM API 进行修改，只是做反向代理，所以几乎主流的 LLM API 它都可以支持，只需要把 baseURL 改成对应 Provider 如 `https://gateway.ai.cloudflare.com/v1/${accountId}/${gatewayId}/{provider}` 即可。

它唯一多提供的一个 API 叫做 [Universal Endpoint](https://developers.cloudflare.com/ai-gateway/providers/universal/) 可以做简单的 fallback。用法是在一个 API 请求里可以填写多个 Provider 的 
query，这样当前面的 Provider 请求失败时会自动调用下一个 Provider。

## 可观测

监控层面除了基础的 QPS 和 Error Rate 这些监控面板，还针对 LLM 的场景提供了 Token，Cost 以及 Cache 命中率的面板。

日志方面和 Worker 的日志很类似，只有实时日志无法查询历史日志。这里感觉做的不太好，Worker 至少还有第三方的方案能保存日志，但是 Gateway 这里却没有了。虽然通过一些实时日志 API 再自己保存的方式也可以，但还是太麻烦了。分析 LLM 请求和响应日志应该是很多 AI 应用后续做优化甚至 fine-tuning 的一个重要环节，这里没有直接集成持久化的方案其实是个硬伤。

## 缓存

缓存方面，Cloudflare 提供的还是基于文本内容完全匹配的缓存，目测是通过 [Cloudflare Workers KV](https://developers.cloudflare.com/kv/) 来实现的。也可以通过 `cf-aig-cache-key` 来实现自定义 Cache Key，包括设置缓存的 TTL 以及忽略 Cache。但是整体看起来基于现在的功能是无法实现语义缓存的，官方文档的说法是语义缓存会在未来提供。

## Rate Limiting

限速方面，Cloudflare 提供的还是传统的基于 QPS 的限速，这块并没有基于 AI 的场景提供基于 Token 的限速，这里未来还有改善的空间。

## Custom metadata

可以在请求的 Header 中增加一些自定义字段，比如用户信息。这些信息可以通过日志进行检索。

# 总结

整体来看 Cloudflare AI Gateway 胜在简单易用，对于之前没有使用 AI Gateway 的用户可以两三分钟就接进来，提供了基础的监控和缓存能力。而且 Cloudflare 还有一些其他配套的 AI 服务例如 Works AI 提供了大量的开源模型的 Serving 和 Worker 提供边缘计算，几个一结合就能搭一套完全 Serverless 的 AI 系统。

他的问题主要在于更深入的功能提供的比较少，而且功能扩展比较麻烦，只能在外围通过 Worker 再来包一层。与其这样 Cloudflare 还不如直接把 AI Gateway 开源出来变成一个模板，用户可以根据自己需求去更改代码或者写插件，没准还能形成一个新的生态。毕竟我高度怀疑现在的 AI Gateway 其实就是个 Worker 模板。