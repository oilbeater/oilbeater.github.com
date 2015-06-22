---
layout: post
title: "阿里大数据竞赛非官方指南第三弹-- LR入门"
description: "最近忙着赶global comm的deadline无暇比赛，当有功夫回过头来看的时候发现比赛已经夹杂了很多非技术的因素在里面了，就连我这个本来是写博客拉粉丝的也有点小不爽。本着我的初心是写博客拉粉丝，我还是再写一弹。"
category: "阿里大数据比赛"
tagline: " Enjoy life!"
tags: [python , bigdata]
img: "http://lh4.googleusercontent.com/-um7AnWJx3Is/T9cH3NM4QXI/AAAAAAAAASc/mR1biDySqMo/s480/Stack_4.jpg"
---

最近忙着赶global comm的deadline无暇比赛，当有功夫回过头来看的时候发现比赛已经夹杂了很多非技术的因素在里面了，就连我这个本来是写博客拉粉丝的也有点小不爽。本着我的初心是写博客拉粉丝，我还是再写一弹。

鉴于我一直感觉LR会出奇迹，这两天开始转型LR，这里介绍一下最基本的LR思路，可以帮助不懂LR的同学上个手，只靠这个指南肯定不会有什么好成绩，不过可以为未来的扩展打下一个基础。用的是最naive的做法，了解的大神们可以绕道了。

LR其实可以指两种算法[linear regression](http://en.wikipedia.org/wiki/Linear_regression)和[logistic regression](http://en.wikipedia.org/wiki/Logistic_regression),其实两者本质上都是线性模型。前者一般用来做数值预测比如房价会涨到多少，明天股票指数是多少；后者一般用来做分类，比如肿瘤是良性还是恶性，明天会不会下雨。尽管机器学习领域还有很多神奇的算法，但是很多情况下这两个LR就可以大杀四方了。一些论文很花哨深度学习现在也很热，但很多时候，工业界用的还是这种简单的模型。

具体到这个比赛上，很明显这是一个分类问题，我们要对每个商家根据用户四个月的行为判断用户下个月到底是买还是不买，就要用到logistic regression。这里简要介绍一下LR的工作形式，输入是一组特征和特征对应的target，得到的结果是特征和最后target的关系，即一组系数。

举个栗子来说：我选取了两个特征，分别是前三个月用户对这个商家的浏览数和购买数，那我的target就是下个月我有没有买这个商家的东西。如果一个人，浏览了5次，购买了2次，下个月买了，就是[5, 2, 1]；如果没有买就是[5, 2, 0]。我们给LR算法输入的训练集就是这样一些东西，而LR输出的就是一组浏览和购买与买或不买之间的系数关系。这样再给一个浏览4购买3的行为你就可以对他是否会买这个东西利用lr的公式得出一个在0和1之间的一个分数，越接近1说明买的概率越大。

其实LR的目的就是**自动求出特征和结果之间的系数关系**，你所专注的应该是找模型以及和模型匹配的特征而不是人工的去找系数关系，这个系数寻找的过程其实才是所有机器学习的模型中算法要干的事情。如果你只是一味的手工调参数的话可以说你根本没用机器学习的方法。

到具体的LR的实现上，主要分为三步。第一步构建训练集合，也就是标记一部分正样本和负样本数据，针对这个比赛来说就是找到一批前几个月和用户与之发生交互，并且下一个月购买了的行为作为正样本（一定要发生过交互），再找一批发生交互但下一个月没有购买的行为作为负样本（注意控制正负样本的比例）。第二步将这些采样的样本放入logistic regression 的计算模型中得到浏览和购买对用户下个月行为的系数关系，这一步可以用现成的库去实现。第三步就是用这些系数关系来预测那些没有标记的行为会不会产生购买行为。

理想情况下可以针对每个商家每个用户各自构建模型，但是出于入门的目的，暂且用一套模型来处理所用用户和商家。

简单的写一下第二和第三部分的代码，其实真到用机器学习算法这一部分是很简单的，并不像有些同学想象的那样难。博主继续用python需要安装pandas和statsmodels两个库可能还需要用到numpy，linux下用pip或者apt-get都可以装上，安装的步骤就自行google了。

    import pandas as pd
    import statsmodels.api as sm  #这就是要安装的两个库，import进来
    
    train = pd.read_csv("sample.csv")    #sample的格式是target,view_num,buy_num即你标记好的训练集，记得第一行一定要是标题
    train_cols = train.columns[1:]       #以第一列以后的列，即二三列作为训练特征，就是以view_num和buy_num为训练特征
    logit = sm.Logit(train['target'], train[train_cols]) #表示以后两列作为训练特征，target列为标记值进行逻辑回归
    result = logit.fit()              #要是开心的话可以用result.summary()看一下回归结果
    
    combos = pd.read_csv("vectors.csv")   #vectors是未标记的特征向量，也就是我们要预测的，格式为uid,bid,view_num,buy_num
    train_cols = combos.columns[2:]
    combos['prediction'] = result.predict(combos[train_cols])  #为每组特征进行预测打分，存储在一个新的prediction列，这里是第五列
    
    predicts = defaultdict(set)
    for term in combos.values:
        uid, bid, prediction = str(int(term[0])), str(int(term[1])), term[4]
    if prediction > POINT:      #可以通过调节POINT的大小来控制最后结果的个数，当然你也可以取分数topN
        predicts[uid].add(bid)


上面的代码主要是参考了[Logistic Regression in Python](http://blog.yhathq.com/posts/logistic-regression-and-python.html)这篇博客进行了化简。更多的用法可以参考这篇博客。

可以看到算法的具体使用还是很简单的，所以麻烦的不是算法本身，麻烦的其实是考察每个算法模型，并对每个算法模型构建合适的特征去采样构建训练集。我构建训练集的代码可要比这个长的多的多了。大部分的分类算法的形式都是类似的，基本上都是上述的三个步骤，大家一个跑通了后其他的算法应该就会轻车熟路了。

用着两个最基本特征训练的结果虽说离进榜还比较远，不过成绩在我看来还是不错的，LR的威力果然很大，毕竟我们采用两个特征，购物车收藏夹也没考虑时间因素也没考虑，大家可以自己尝试着加上去，应该会有不错的结果。或者还能考虑把用户聚类或者把商家聚类，对每一类建立一个模型，结果肯定也会比现在好。LR的扩展性还是很好的，剩下的就看大家怎么挖掘特征了。不过算法的最好效果怎样就不好说了，因为训练的数据太少了，特征加多了很容易over fitting。

PS：LR真的是大杀器，建议如果是想通过比赛来进入机器学习这个领域的同学可以把比赛放一放好好研究一下NG的[machine learning](https://www.coursera.org/course/ml)基本上看完logistic regression就会对这个算法有个比较直观的了解。嗯我是NG老师的脑残粉，但是NG老师讲完LR后会说你凭借LR就可以秒掉硅谷大部分的data analyst这件事你不要太当真。

- [非官方指南第一弹在这里](http://oilbeater.com/2014/03/16/the-setup-of-bigdata-race/)
- [非官方指南第二弹在这里](http://oilbeater.com/2014/03/24/the-bigdata-race-2/)


