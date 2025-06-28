---
title: Kube-OVN 是如何自动修复 CVE 的
date: 2025-06-28 00:02:21
tags:
---

> 这篇博客是内部分享的一个大纲，并没有做仔细整理，大体思路就是捕获所有 Kube-OVN 的依赖：操作系统，Golang，程序依赖，环境组件（k8s,kubevirt 等），然后激进的实时更新所有依赖做到动态清零。

Kube-OVN CVEs 问题修复的流程经历了如下几个阶段：
- 发版/按需统一进行手动修复
- 每次 commit 检测可修复安全漏洞，手动进行修复
- master 依赖自动更新，发版分支部分依赖自动更新，少量手动修复
- 未来目标：所有依赖自动更新，避免手动修复

## 按需修复

优势：
- 相比每个安全漏洞单独修复，整体修复频次低
劣势：
- 发版集中修复，研发还要兼顾发版期间赶进度，测试，bug 修复，时间压力大
- 依赖更新没有经过日常验证，存在未知的风险
- 大部分安全修复工作没有实际意义还需要花费人工精力

## 每次 Commit 检测修复

增加工作：
- 流水线增加 trivy 扫描，存在安全问题无法合并代码
- https://github.com/kubeovn/kube-ovn/blob/master/.github/workflows/build-x86-image.yaml#L3437
- https://github.com/kubeovn/kube-ovn/actions/runs/15760235247?pr=5376

优势：
- 将 CVE 修复打散到平时，发版时时间压力较低
- 可以快速发版
- 大部分依赖更新已经得到了日常自动化测试的验证，风险也较低
劣势：
- 最后一次提交和发版扫描之间存在时间差，理论上会遗漏一部分 CVE
- 会干扰平时正常功能提交，bug 修复，提交经常因为不相关的 CVE 问题被阻塞
- 大量的手动修复

## 所有依赖自动更新

只要依赖更新版本就尝试更新，不考虑是否是安全更新。尝试解决比 CVE 修复更大的一个问题，自动就解决了 CVE 问题的修复。

我们的依赖项：
- OS 镜像及其依赖：`ubuntu:24.04`, `apt-get install ....`
- Go 语言版本，以及代码依赖库
- 上游依赖：`OVS`, `OVN`
- 其他协作组件依赖： `kubernetes`, `kubevirt`,`multus`, `metallb`, `cilium`, `talos`
- 采用比较激进的更新策略，依赖大版本更新我们也会尝试更新


要做的事情：
- OS 镜像部分增加流水线每天重新构建，自动修复 OS 和 apt 库里解决的问题
	- https://github.com/kubeovn/kube-ovn/blob/master/.github/workflows/build-kube-ovn-base.yaml
	- 每日自动无需人工干预
- Go 相关使用 renovate 进行自动更新
	- Go 版本，`go.mod` 里的所有依赖版本
	- 实时更新 + auto merge
	- 出现合并问题手动处理
	- https://github.com/kubeovn/kube-ovn/pull/5354
	- https://github.com/kubeovn/kube-ovn/blob/master/renovate.json
	- 不需要特殊配置，按照 renovate 自动检测流程来即可
- 上游组件依赖
	- OVS OVN 每日构建，策略更激进直接从上游分支构建，上游不发版我们也会更新
	- 相信上游都是 bugfix，我们这样可以增强稳定性
- 其他组件
	- 使用 renovate 的自定义正则匹配，Dockerfile, Makefile, Action 里所有依赖软件版本自动更新
	- https://github.com/kubeovn/kube-ovn/issues/5291
	- https://github.com/kubeovn/kube-ovn/blob/master/Makefile

优点：
- 大部分 CVE 会在不知道情况下被修复，少量可在一天内自动修复，特殊情况再手动修复
- 大量上游的 bugfix，性能提升和新功能被自动合入，软件整体稳定性提升
- 大量的版本适配验证工作，如 k8s 版本更新，KubeVirt 版本更新的适配验证也都自动进行，风险提前知晓
- 人工干预量较少

劣势：
- 依赖更新多比较吵，需要设置聚合策略
- 更新量太大无法人工测试，需要有自动化测试保证
- 需要积极适配上游版本变化
- 存在上游新版本不稳定风险，目前两年内遇到过两次

## renovate 相比 dependabot 优势

- 可以自定义依赖捕获，Dockerfile、Makefile 里的非标准依赖可以捕获
- 可以在非 master 分支运行
- 有 auto merge 能力
- 
## 还未解决的问题

- 自动化测试误报导致无法自动合并
- 已发版分支的 Go 相关更新还未自动化
	- renovate 的 security-only 策略效果还未知
	- https://github.com/kubeovn/kube-ovn/blob/master/renovate.json#L45
	- 发版分支可能需要重新定义策略
- 部分依赖还没有自动更新