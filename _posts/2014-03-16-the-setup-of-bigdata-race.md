---
layout: post
title: "阿里大数据竞赛非官方指南"
description: "鉴于我的水平大概不再争夺奖金的行列，写一些基础入们的东西，希望有感兴趣的同学可以借这个机会上手。"
category: "阿里大数据比赛"
tagline: " Enjoy life!"
tags: [python , bigdata]
img: "http://lh4.googleusercontent.com/-um7AnWJx3Is/T9cH3NM4QXI/AAAAAAAAASc/mR1biDySqMo/s480/Stack_4.jpg"
---

大赛的地址在[这里](http://102.alibaba.com/competition/addDiscovery/index.htm)。

鉴于本小弱非数据挖掘出身，只是在coursera上跟过Ng的机器学习，估计最后做一个regression再上一个协同过滤就到极限了，就不去争名次了。写一些step by step 的入门东西，帮助感兴趣的新手快速入手，希望大家可以快速的参与进比赛来，如果真的有帮助到某个同学的话，那就苟富贵勿相忘了。

首先扫一眼数据发现时间那一列居然是中文，先转成可处理的日期格式，就假设数据是13年的好了。

    def parse_date(raw_date):
        entry_date = raw_date.decode("gbk")
        month = int(entry_date[0])
        if len(entry_date) == 5:
            day = 10 * int(entry_date[2]) + int(entry_date[3])
        else:
            day = int(entry_date[2])
        return 2013, month, day

由于不能实时的去测试算法的效果，现阶段只能将给的数据分成训练集和验证集，我的策略是前三个月当训练集，最后一个月当验证集。这里好像吐槽一下阿里，你好歹弄个一天一测试也好啊，你一周给一次测试机会让我们怎么持续优化算法啊？一天跑一次测试对你们有什么难度么？这种东西你让我们实时测试也不是什么技术难题啊！

尽管对基于时间序列的分析半点经验都没有，但是还是知道越靠后的内容权重应该越大，于是以4月15号为零点，在把数据分成两个集合的同时把时间部分重新处理一遍。同时验证集合只需要购买的记录就可以了，就把没用的记录过滤掉。

    def split_file(raw_file, seperate_day, begin_date):
        train = open("train.csv", "w")
        validation = open("validation.csv", "w")
        raw_file.readline()
        for line in raw_file.readlines():
            line = line.strip()
            entry = line.split(",")
            entry_date = date(*parse_date(entry[3]))
            date_delta = (entry_date - begin_date).days
            if date_delta < seperate_day:
                train.write(",".join(entry[:3]) + "," + str(date_delta) + "\n")
            elif int(entry[2]) == 1:
                validation.write(",".join(entry[:2]) + "\n")
                print ",".join(entry[:2])
        validation.write("99999999999,9" + "\n")
        train.close()
        validation.close()

生成了验证集合后，需要将结果归并一下，估计阿里那边的测试也就是个文本对比，所以把验证集合的结果也归并成提交格式要求的那个样子。

    def generate_result(validation):
        entrys = validation.readlines()
        entrys.sort(key=lambda x: x.split(",")[0])
        result = open("result.txt", "w")
        for index, entry in enumerate(entrys):
            uid, tid = entry.strip().split(",")
            if index == 0:
                cur_id = uid
                cur_result = [tid]
            elif uid == cur_id:
                cur_result.append(tid)
            else:
                result.write(cur_id + "\t" + ",".join(set(cur_result)) + "\n")
                cur_id = uid
                cur_result = [tid]
        result.close()

然后就是把这几个函数都整合起来，就可以省成初步的训练集，验证集，和最终结果了

    SEPERATEDAY = date(2013, 7, 15)
    BEGINDAY = date(2013, 4, 15)
    raw_file = open("t_alibaba_data.csv")
    split_file(raw_file, (SEPERATEDAY - BEGINDAY).days, BEGINDAY)
    raw_file.close()
    validation = open("validation.csv")
    generate_result(validation)

由于官方一周才能跑一次测试（再次强烈吐槽）我们本地也要自己完成在验证集合上的测试，需要对比算法预测出来的结果和验证集上的结果：

    from collections import defaultdict

    predict_num = 0
    hit_num = 0
    brand = 0
    result = defaultdict(set)
    f = open("result")
    for line in f.readlines():
        line = line.strip()
        uid, bid = line.split("\t")
        result[uid] = bid.split(",")
        brand += len(result[uid])
    f.close()


    f = open("predict.txt")
    for line in f.readlines():
        line = line.strip()
        uid, bid = line.split("\t")
        bid = bid.split(",")
        predict_num += len(bid)
        if uid not in result:
            continue
        else:
            for i in bid:
                if i in result[uid]:
                    hit_num += 1

    print "predict num is ", predict_num
    print "hit num is ", hit_num
    print "total brand is ", brand

    precision = float(hit_num)/predict_num
    callrate = float(hit_num)/brand
    print "precision is ", precision
    print "call rate is ", callrate

    print "F1 is ", 2*precision*callrate/(precision+callrate)

剩下的要做的就是不断的改进算法然后用上面的程序来测试效果了。不过我在本机的验证集合上测试出来的结果和官方数据测试的结果还是有些出入的，不过现阶段貌似也只能这么做了。

为了奖励看到最后的人，透漏一点小秘密，直接预测最后一个月买过东西的人再重新买一次也能获得9%的准确率，当然召回率很低了，不过至少应该比盲狙的结果好。

再说的直白点，即使你啥都不做就是把我的程序跑通了，那么你直接把前面验证集的结果提上去就能获得一个还算体面的准确率，多的我就不说了嗯。

