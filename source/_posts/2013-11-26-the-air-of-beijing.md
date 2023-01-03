---
layout: post
title: "基于twitter数据的美帝PM2.5分析"
description: "数据来源是twitter上的BeijingAir每小时公布的美国驻北京大使馆pm2.5情况。物理上来讲大使馆是和北京比较近，但逻辑上来讲大使馆属于美国领土一部分，所以测量出来的应该是美国领土的pm2.5情况，就让我为生活在水深火热的万恶资本主义国家的人民揭示一下他们悲惨的命运吧。"
category: "小工具"
tagline: " Enjoy life!"
tags: [生活 , 随想]
img: "http://lh5.googleusercontent.com/-78iIVZ1OVj4/UpQwxHvWCEI/AAAAAAAAAeg/2erFkL5e3pA/w676-h422-no/hour_summary.png "
---

数据来源是twitter上的BeijingAir每小时公布的美国驻北京大使馆pm2.5情况。物理上来讲大使馆是和北京比较近，但逻辑上来讲大使馆属于美国领土一部分，所以测量出来的应该是美国领土的pm2.5情况，就让我为生活在水深火热的万恶资本主义国家的人民揭示一下他们悲惨的命运吧。

由于twitter提供的API只能获取到最近3200条的数据，时间跨度从2013年7月23日到2013年11月25日共124天2393个小时的数据,由于有些时间的数据显示为No data，所以不是个全量数据。数据分为每小时，每十二小时和每二十四小时的pm2.5浓度，空气质量指数，以及空气质量评级。其中空气质量的评级采用的是[EPA2012的标准](http://www.epa.gov/pm/2012/decfsstandards.pdf):

![air standard](http://lh3.googleusercontent.com/-wKowfkSEmjA/UpQ1Ad9aozI/AAAAAAAAAes/_6MP3ZVYmbs/w672-h368-no/air_standard.png "airstandard")

惯例上来讲这是发达国家的标准，发展中国家是不能用这个标准比的，可谁让美帝大使馆是美国领土呢，废话不多说了，直接上统计结果图。

首先是按小时统计的空气质量图，统计了2393个小时的空气质量比例：

![hour summary](http://lh5.googleusercontent.com/-78iIVZ1OVj4/UpQwxHvWCEI/AAAAAAAAAeg/2erFkL5e3pA/w676-h422-no/hour_summary.png "hour summary")

可以看到美帝人民大多数时间都是在呼吸着悲惨的空气。Good的情况将将过8%

然后是一张按小时的时间分布图：

![hour distribution](http://lh3.googleusercontent.com/-IvCawUcR8Es/UpQwjAFBarI/AAAAAAAAAeU/P8dYtRY_9mM/w1277-h416-no/hour_distribution.png)

还是有明显的波峰波谷的，或许一个专业的数据分析专家可以计算出一个pm2.5的变化周期。而且按照往年的经验来看秋天的空气质量会好一些，但是今年秋天却有加重的趋势。好在最近还没有出现峰值突破500的情况，但是去年冬天有一次破1000的峰值，不知道随着冬天的到来，全面烧暖气之后会不会继续恶化。

然后是一张每小时的pm2.5平均水平：

![hour average](https://lh5.googleusercontent.com/-3P8H14F6bVY/UpQwhrSY_AI/AAAAAAAAAd8/R60sJdMRMcw/w679-h319-no/hour_average.png)

可见白天的时候其实还是一天中空气质量较好的时段，波谷出现在下午三点，在六点过后迅速恶化，在凌晨达到峰值，想我以前晚上出去跑步真是不要命了。从hour的水平看平均值在70到110之间是处于一个moderate的级别，但是EPA的标准是分each hour 和24-hour average的，其中24-hour average 的要求会比each hour的更苛刻一些，毕竟一个小时处于这种水平还能接受，24小时的话就不行了。

下面就是组day level的数据，空气质量水平依据的是EPA 24hour average，首先是按天的分布图：

![day distribution](http://lh4.googleusercontent.com/-vDkAhRcyzhE/UpQwhdzjFbI/AAAAAAAAAeE/t9F8JHRmeuQ/w1278-h293-no/day_distribution.png)

相当于对时间分布图做了一个光滑，可以看出周期大概是7到8天的样子，后半段比前半段恶劣的也很明显一些。

最后是一个按天的空气质量比例图：

![day summary](http://lh3.googleusercontent.com/-DpCWU3maeRw/UpQwhXPgRHI/AAAAAAAAAeA/zDOJL1t-pS4/w779-h399-no/day_summary.png)

由于24 hour average的标准更严格，好天气的比例相对于每小时的比例严重缩水了，其实在124天的样本里只有一天的水平到了Good,也就是每个季度里只有一天达到了Good的标准，即便算上了moderate也只有22天，就是说样本数据里六分之一的天气还是正常的，剩下六分之五都是不健康的天气，实在是为生活在水深火热的美帝人民感到悲哀。你们于其天天和中国谈人权问题，还是先治理一下自己国家的空气吧。
