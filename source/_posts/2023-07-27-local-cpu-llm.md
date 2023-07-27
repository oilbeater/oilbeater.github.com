---
title: 如何在本地用 CPU 跑大模型
date: 2023-07-27 10:51:07
tags: [llama, AI]
---

之前觉得大模型在本地运行是个不可能的事情，我甚至没有一块 GPU。但是尝试了一下 llama.cpp 发现几分钟就把 Meta 最新开源的 Llama 2 在 CPU 上运行起来了，速度和质量都还可以接受，很多想法突然就变得可行了。记录一下搭建的过程，希望对感兴趣的人有帮助。

# 需要的配置

尽管不需要 GPU 和加速卡，但是大模型对磁盘和内存还是有需求的，我运行的是 Llama 2 7B 的模型，经过了 GGML 处理，选择了 int8 的精度。这个模型跑起推理来大概需要 7G 的磁盘空间，运行起来也需要 7G 左右的内存，长期运行的话内存有 10G 会比较保险。CPU 的话 1 核也能跑，但给到 6 核会比较流畅。

# 搭建步骤

下载模型：

```bash
wget https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGML/resolve/main/llama-2-7b-chat.ggmlv3.q8_0.bin
```

这是一个处理过的模型，减小了体积和精度，专门为端侧运行做了优化，也不需要申请 Meta 的授权直接就能下载。

下载并安装 [llama.cpp](https://github.com/ggerganov/llama.cpp)：

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
make
```

这是一个高性能的 Llama 推理工具集，可以方便的做 chat，api 等等服务。

移动模型文件到对应目录：

```bash
mv ../llama-2-7b-chat.ggmlv3.q8_0.bin models/
```

好了现在你就可以在本地运行一个 chat 了：

```bash
./main -m ./models/llama-2-7b-chat.ggmlv3.q8_0.bin -c 512 -b 
1024 -n 256 --keep 48 \
    --repeat_penalty 1.0 --color -i -t 4 \
    -r "User:" -f prompts/chat-with-bob.txt
```

# 更多配置

在 examples 目录下还可以看到 llama.cpp 的其他用法，比如提供 API 服务，提供 embedding 和 fine-tune，甚至还有一个兼容 OpenAI API 的转换器。

如果你的机器有 GPU 或者用的是 M 系列芯片的 Mac 那么可以通过 make 参数提高推理的性能。

如果你的机器再厉害一些可以考虑去 huggingface 上去下载更大参数量的模型。

# 为什么要本地运行大模型

其实我手头 OpenAI 的 GPT3/GPT3，Google Bard，Claude 2 的 API 使用权都有，那为啥还要费心思在本地用 CPU 跑质量并不如他们的大模型呢？

第一个原因是穷，和我想做的事情相关。我想用大模型做代码分析和信息摘要，一个项目可能有上万个 commit 跑一遍就破产了。

第二个原因是穷，买不起 GPU 和 M 系列的 Mac，只能找穷人的方法。

第三个原因是我觉得未来端侧的大模型会更实用，也更能贴近个人的场景进行垂直方向的定制化，想借着这个机会看看这个领域到啥地步了。


