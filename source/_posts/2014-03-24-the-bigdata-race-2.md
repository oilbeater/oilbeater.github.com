---
layout: post
title: "阿里大数据竞赛非官方指南第二弹"
description: "博主由于各种deadline最近没那么多时间搞这个，结果第二周勉强还在前500。这两周估计更没什么时间了，前500估计更悬了，不过好在本来我也是来写博客的，求粉求关注。"
category: "阿里大数据比赛"
tagline: " Enjoy life!"
tags: [python , bigdata]
img: "http://lh4.googleusercontent.com/-um7AnWJx3Is/T9cH3NM4QXI/AAAAAAAAASc/mR1biDySqMo/s480/Stack_4.jpg"
---

第一弹在[这里](http://oilbeater.com/2014/03/16/the-setup-of-bigdata-race/).

第一弹由于时间匆忙代码里面有很多小bug，感谢k39ec的指正，最新的代码第一弹里面已经更新了。

博主由于各种deadline最近没那么多时间搞这个，结果第二周勉强还在前500。这两周估计更没什么时间了，前500估计更悬了，不过好在本来我也是来写博客的，求粉求关注。

已经有很多人的成绩比我好了，我就简单说一下我的算法思路，大家可以借鉴一下，代码就先不贴了，实在没时间再整理代码把可读性弄好了。

###我的策略

####周期性物品

大家应该都发现有些商品是会重复购买的，不妨就把那些可能会周期购买的物品如果这个用户之前买过，就让他再买一次。

具体思路就是看每个用户每个月都买了那些物品，如果有一个用户（或者可以自己改阈值）在任意两个月内购买了同一物品，那么就把这个物品标志位周期性物品。遍历完所有用户找到所有的周期性物品。如果用户购买过某个周期性物品的话就让他下个月再买一遍好了。

####热门物品

找到上个月卖的最好的10个物品，如果某个用户上个月对这个物品产生了交互，点击、收藏、购物车，如果有购买没有买的太多的话下个月就让他买

####关联物品

之前了解一点[Apriori ](http://en.wikipedia.org/wiki/Apriori_algorithm)这种关联算法，时间有限没有按照原算法实现，做了个化简版本的。指导思想就是看用户买过一个物品后更可能会买什么其他物品。

大致算法是首先获取用户的购买序列去掉重复部分比如原来是[a,b,a,c]，变成[a,b,c]。

列出所有的二元组，表示买过一个物品后又买过另一个物品，即变成(a, b), (a, c), (b, c)

对所用用户的购买序列进行这种操作，得到所有的二元组并统计每个二元组出现的次数。比如所有二元组是(a, b), (a, c), (b, c)，(a, c), (b, c),  (b, c)，得到的结果就是{(a, b) : 1, (a, c) : 2, (b, c) : 3}。现在就得到了买过每种物品后续又买了哪个物品的次数。

这个统计有一个问题即，如果b是热门物品的话，很多人都买过，会导致和他关联的物品次数增高。比如淘宝只有10个用户，只有三种产品——衣服，ipad，ipad套，所有人都会买衣服，有3个人买了ipad，这三个人都买了ipad套，还有两个人买了ipad套送人，那么二元组的统计就是(衣服， ipad套) ：5, (ipad, ipad套) ：3。但是明显ipad和ipad套的关联应该更强，衣服和ipad套的次数多只是因为衣服太热了。

解决方案就是统计每个商品被多少个用户购买过，然后用每个二元组出现的次数除他们中第一个物品被几个用户购买，得出每个二元组的一个分数。比如上面的例子中，(衣服， ipad套) 得分是0.5，(ipad, ipad套) 得分是1。

 然后根据每个用户之前的购买情况，统计每个可能会购买的物品分数，比如买过衣服又买过ipad那么他买ipad套的分数就是1.5。当分数大于某个值的时候就让用户下个月购买。

###其他的建议

这些想法我都没有具体验证，大家可以参考。

####最后一个月

感觉最后一个月的数据其实是最重要的，因为用户还是倾向于购买新的产品，而不会把三个月前不买的东西再翻出来买了。可以尝试一下多观察某个用户两个月的数据找找规律。因为cf之类的传统算法貌似经证实不太好用，所以靠谱的方法还是多观察数据。

####关于数据清洗

看到有些人把某些成交量很小的商品给去掉了，问题是有可能这些物品是数据集最后几天加入的，根据上一条的思想，他们的权重可能会很大，没准正好是上了一款新品下个月大卖。所以清理数据的时候要注意一下时间点。

####LR可能会出奇迹

这只是个人感觉了，最近没什么精力搞，只是感觉很合适。

希望人品保佑能进Season 2 有机会接着写非官方指南。