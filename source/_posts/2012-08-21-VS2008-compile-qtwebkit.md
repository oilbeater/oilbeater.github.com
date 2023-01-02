---
layout: post
title: "VS2008编译Qtwebkit"
description: "为了证明自己这一个月没有打酱油，不过一个月写出这么个环境搭建的东西也只能证明我打酱油了，也为了回去能把环境搭起来，还是写那么两笔吧。"
category: "Webkit"
tagline: "Hack the life"
tags: [webkit]
img: "http://lh6.googleusercontent.com/-Z7ZgfMMC0ug/UDLqG1HYL_I/AAAAAAAAAVk/0BlqB3-i35Q/s215/webkit.png"
published: true
---

为了证明自己这一个月没有打酱油，不过一个月写出这么个环境搭建的东西也只能证明我打酱油了，也为了回去能把环境搭起来，还是写那么两笔吧。官方的安装指导在[这里](http://trac.webkit.org/wiki/BuildingQtOnWindows)但是按照这个指导是肯定编译不过去的，所以还是看我的吧。安装环境的过程其实一点也不麻烦
### 安装VS2008
 官方链接在[这里](http://www.microsoft.com/zh-cn/download/details.aspx?id=3713)第一次找的时候不知道为什么脑抽筋直接下了一个MSDN，装完后还傻傻的找启动程序在那里？在哪里？
### 安装Qt for VS2008
 网上很多教程都说要自己从编译Qt，实践证明直接用安装包就好了，链接在[这里](http://qt.nokia.com/downloads/windows-cpp-vs2008)安装好后记得要在环境变量PATH里把qt安装目录下面的bin路径加入到PATH中，因为vs编译的时候需要找到qmake的路径。
### 下载qtwebkit源码
官网的nightly版本是编译不出qt版的所以还是用[这个](http://get.qt.nokia.com/qtwebkit/QtWebKit-2.2.0.tar.gz)吧。
### 下载pthread
 不知道为什么里面会用到pthread这种和平台相关的库，不过好在pthread现在也有windows平台的了，链接在[这里](ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip)
将 pthreadVC2.lib  pthreadVC2.lib 和pthread.h （看一下是x86版还是x64版）扔到qt安装目录下的lib中
### 下载WebKit Support Library 
  一个水果公司提供的库文件去[这里](https://developer.apple.com/opensource/internet/webkit_sptlib_agree.html)下载，**不用解压**，直接放到webkit源码目录下即可
### 安装GUN 工具包
**记住安装路径中不能有空格** 
由于某些众所周知的原因下面的链接可能打不开

* [Bison](http://gnuwin32.sourceforge.net/downlinks/bison.php)
* [GPerf](http://gnuwin32.sourceforge.net/downlinks/gperf.php)
* [Grep](http://gnuwin32.sourceforge.net/downlinks/grep.php)
* [Flex](http://gnuwin32.sourceforge.net/downlinks/flex.php)
* [Libiconv](http://gnuwin32.sourceforge.net/downlinks/libiconv.php)

然后记得在PATH中加入他们的bin文件夹路径
###安装Python 和 Perl
由于编译的时候要执行许多脚本生成代码，又由于他们不是用一个语言写的所以这两个都要装。
Perl在[这里](http://www.activestate.com/activeperl/downloads)
Python 需要2.x版，链接在[这里](http://www.python.org/download/)由于某些众所周知的原因你可能打不开。然后再把python的安装路径和perl的bin路径加到PATH中就不需要再安装别的东西了。需要安装的东西一点也不多。
###修改代码bug
像这么光荣伟大正确的开源工程release出来的代码怎么可能会有问题能，绝对不可能有问题，一定是下载程序出错了。
打开QtWebKit-2.2.0/Source/JavaScriptCore/JavaScriptCore.pri 把95行的LIBS += -lwinmm 改为LIBS += -lwinmm -lAdvapi32。不然的话链接时会出错，这一定是下载程序偷懒少下造成的。然后还有一个错误，具体在哪里我给忘了，不过是个编译的时候看一眼就知道怎么改的bug还是先编译吧。
###编译Qtwebkit
在源码文件夹里新建WebkitBuild文件夹，在里面再新建Debug和Release两个文件夹，注意大小写。
在开始菜单里打开“Visual Studio 2008 命令提示”cd到源码文件夹然后敲入“perl Tool\Scripts\build-webkit --qt --debug --minimal”就可以开始漫长的编译了。编译的时候会提示一个错误中断，什么错误文件末尾一类的错误。打开提示错误的代码发现那一行是由于有两个中文引号造成的，根据上下文初步估计他是想写转义后的双引号，改成转义后的双引号后就可以编译通过了。这一定是有人挖webkit的墙角才会在release版里有这么弱智的问题。
经过很短的编译时间，大概两个小时吧，就可以在\QtWebKit-2.2.0\Source\WebKit\win\WebKit.vcproj下面找到VS工程文件了。在QtWebKit-2.2.0\WebkitBuild\Debug\bin下可以找到编译好的可执行文件QtTestBrowser了。打开QtTestBrowser然后再用VS的调试attach上去就可以加断点调试了。
Qtwebkit的环境搭建真的好容易啊好容易。
