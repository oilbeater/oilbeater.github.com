---
title: AI Gateway 调研之 Kong, Gloo 和 Higress
date: 2024-08-26 07:39:23
tags:
    - AI
    - Gateway
    - Kong
    - Gloo
    - Higress
---

上篇[博客](2024-08-25-ai-gateway-cloudflare)介绍了 Cloudflare AI Gateway，这篇集中介绍一下 Kong, Gloo 和 Higress 因为这三者有一定的相似性，都是从原有的 API 网关基础上进行扩展，通过插件的方式支持了一系列 AI 相关的功能，在交付上也是传统的软件部署方式。这几个算是传统 API Gateway 迎接 AI 浪潮的代表，其中 Higress 更是把产品 Slogan 直接从 Cloud Native API Gateway 变成了 AI Gateway，虽然打不过就加入，但这样变来变去不怕人说没根么：）

由于这三款产品都需要额外的部署开通，有的 AI 功能还是商业版才有，所以下面的分析都是根据看文档总结而来，可能存在着和实际不符的情况。

|  功能  | Kong     | Gloo     | Higress | 备注 |
| ----- | -------- | -------- | ----- |  --- |
| 技术栈 | Nginx + Lua | Envoy + Go | Envoy + WASM | 虽然几家都提供了插件机制，但是和网关的耦合程度都比价高，非网关的开发者上手还是有一定难度 |
| 日志监控  | 每个 AI 插件会将元信息，如模型名、Token 开销费用等信息加入到 Audit Log 中，但是似乎没有自定义元信息的功能，需要通过其他插件来辅助完成 | 似乎没有在 AI 这块对日志有功能增强，还是通用的监控 | 日志和监控中增加了 Token 的用量，提供的信息和 Kong 类似，也不具备自定义元信息的功能 | 如果能增加一些自定义元信息，并支持记录 Request 和 Response 里 Message 信息就更好了 |
| Proxy | Kong 提供了归一化的 API 能够用一套统一的 API 去调用不同的 LLM API，这对开发者还是比较友好的能够不需要大改应用代码就能用不同的 LLM | Gloo 没有提供归一化的 API，只是反向代理到上游 LLM API | Higress 支持将不同的 LLM API 统一转换成 OpenAI API，这对开发者来说也比较友好，毕竟目前生态里还是直接用 OpenAI API 的比较多 | 虽然我觉得是否提供归一化的 API 没那么重要，不过一定要归一化的话归一化成 OpenAI 格式的会好些 |
|  API Key 管理  | 客户端的 Key 可以和上游的 Key 不一样，相当于把 Key 在网关层做了一层屏蔽 | 客户端的 Key 可以和上游的 Key 不一样，相当于把 Key 在网关层做了一层屏蔽 | 直接从客户端透传 Key 给上游 | 个人感觉 Gloo 这个功能还比较实用，避免了在 LLM 那里真实的 Key 被过多业务方知道，安全和可控性会更好一些 |
| Cache | 当前版本没有提供 LLM Cache 相关能力，据说会在 3.8 版本提供 | 提供了语义 Cache，看配置是调用了 OpenAI 的 Embedding 和 Redis 的 Vector，不过没看到更细粒度的比如 TTL 相似度的配置 | 提供的还是文本匹配的缓存，相比全文本可以通过 JSON PATH 的语法选择部分 Message 做缓存，看配置也是利用 Redis，不过不支持语义 Cache | Gloo 提供的语义 Cache 看起来更高级一些 |
|  请求/响应改写  | 可以在 Request 和 Response 阶段分别加 prompt 对 message 进行改写，相当于一个小型的 workflow | 只提供了 prepend system prompt 的能力，感觉提升有限  | 和 Kong 类似提供了用 prompt 进行改写的能力，不过现在只支持通义千问的 LLM 感觉不够开放 |  |
| RAG | 目前没有相关功能的插件 | 可以对接一个 postgres 和 OpenAI 的 embedding Token 这样可以自己提供一些文本来做 RAG | 和 Gloo 的功能类似，不过只支持阿里云的向量服务和通义千问，还是感觉不够开放 | 感觉 RAG 的配置参数都比较少没有相似度，或者爬取网页的接口，只能做比较简单的 RAG |

# 总结

这三款产品由于只是看文档没有真实使用过，里面的内容很可能有不准确的地方，希望了解的同学可以指正。

总体来看三款产品都是 LLM 爆发前就存在的，之前也不是专门为 AI 场景设计的，很多使用的配置可能懂 Kubernetes 的更能看懂。尤其是 Gloo 的文档全是 YAML 和 CRD 的配置，浓浓的 Cloud Native 味道，Higress 看上去也是各种 ConfigMap 脱离 Kubernetes 是否还能用好我是心里存在疑虑的。

Higress 虽然没根了，但是整体看 AI 功能做的还是最完整的，发力也比较明显。Kong 感觉还只是试探性的做了些功能，而 Gloo 是把所有 AI 相关功能都放到商业版里了。如果 Higress 能把开发性做好不是被通义千问和阿里云上各种服务绑定的话我觉得还是个不错的项目。

最后的依赖还是这三款产品的扩展性可能都存在一定难度，需要高度了解网关相关的逻辑并掌握 Lua 或者 WASM 这样非主流的语言。而 AI 应用现在的形态其实还存在很多变化的可能，对应的 API 和需要的通用能力可能也有比较大的变化，比如怎么做 RAG，怎么做 Cache，怎么编排 LLM 都没有确定下来。不知道现在的架构会不会对他们未来的功能灵活变化产生影响。
