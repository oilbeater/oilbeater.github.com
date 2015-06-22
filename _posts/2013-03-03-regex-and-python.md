---
layout: post
title: "正则 in Python"
description: "简单说一下为什么要用正则表达式，因为可以用简洁的方式处理几乎所有的字符串查找和匹配，节省生命，节省脑子。"
category: "Python"
tagline: "Hack the life"
tags: [python , re]
img: "http://lh6.googleusercontent.com/-vQcn-f1J1Cg/Ui06Xx3NPhI/AAAAAAAAAa4/1B9jH_ing7o/w314-h160-no/original_pot5_38e700011e971190.jpg"
published: true
---

简单说一下为什么要用正则表达式，因为可以用简洁的方式处理几乎所有的字符串查找和匹配，节省生命，节省脑子。

文中的内容主要参考自[《精通正则表达式 第三版》](http://book.douban.com/subject/2154713/)
和[《Python 核心编程 第二版》](http://book.douban.com/subject/3112503/)以及[Python re](http://docs.python.org/2/library/re.html)，主要做一下总结和笔记。感兴趣的同学可以深入看一下这两本书最后再看一下标准。

## Regex 中的特殊字符和规则

这里介绍的是Python 2.7支持的部分，有些工具会支持更多高级的用法

### 位置匹配

^	匹配行首

$	匹配行末


###贪婪匹配

.	匹配任何字符（换行符除外）

<p>*	匹配任意次或不匹配</p>

<p>+	匹配至少一次</p>

?	匹配一次或不匹配

{N}	匹配N次

{M:N}	匹配M次到N次


###非贪婪匹配

<p>*?,+?,??,{M:N}?</p>

###多选结构

\[...\]	匹配出现任一字符

\[0-9a-zA-Z\]	范围匹配

\[^...\]	不匹配任一字符

re1|re2	匹配任一表达式

###分组

(...)	分组并捕获

(?:...)	分组不捕获

###环视

(?=...)	顺序肯定环视

(?!...)	顺序否定环视

(?<=...)	逆序肯定环视

(?<!...)	逆序否定环视

###特殊字符

\number	捕获分组匹配

\b	匹配单词边界(\A,\Z)

\d	匹配数字

\D	匹配非数字

\s	匹配任一空白

\S	匹配非空白

\w	匹配任何数字和字母

\W	匹配任意非数字和字母

## Python re库

compile	编译出re对象

I	忽略大小写flag

M	多行模式flag

search(paattern,string,flag)	匹配并返回match对象

split(pattern,string,maxsplit,flags)	按pattern分割，pattern加括号会将分隔符输出

findall/finditer(pattern,string,flags)	返回匹配列表/迭代器

sub/subn(pattern,repl,string,count,flag)	替换/替换并返回替换次数

## Python match 对象

group([group1,...])	返回捕获分组内容

groups()	返回捕获内容列表

groupdict()	返回列表名

start、end([group])	返回匹配位置开始/结束

re	匹配的re表达式

string	源字符串
