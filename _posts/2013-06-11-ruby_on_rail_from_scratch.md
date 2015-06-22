---
layout: post
title: "Ruby on Rails Ubuntu下从零开始到在线网站"
description: "由于实习的东西有一部分是ruby on rails的就在自己机器上也搭个环境走个流程熟悉一下概念。"
category: 
tagline: " Hack the life！"
tags: [ruby]
img: "http://lh5.googleusercontent.com/-kUKhpCIDfsA/Ui06U9kkjpI/AAAAAAAAAZ0/zhk8uETi6fk/w845-h846-no/original_V0HB_527c0000272f125d.jpg"
---
由于实习的东西有一部分是ruby on rails的就在自己机器上也搭个环境走个流程熟悉一下概念。主要是翻译自[How to install Ruby (and RVM) on Ubuntu (for technotards)](http://blog.coolaj86.com/articles/installing-ruby-on-ubuntu-12-04.html)和[Ruby on Rails Tutorial](http://book.douban.com/subject/10813224/)加上自己碰到问题的总结。

## 基本概念

### Ruby？

一个很适合写web的脚本语言，很多博客系统都是ruby写的，包括[octopress](http://octopress.org/)，[nanoc](http://nanoc.ws/)还有本博客用的[jekyll](jekyllrb.com)，当然还有著名的不存在的网站[twitter](http://twitter.com)和著名的有时不存在网站[github](https://github.com)。Ruby还是门很简单的语言，想大致学一下的话可以看一下[Ruby in Twenty Minutes](http://www.ruby-lang.org/en/documentation/quickstart/)。

###Rails？

一个开源的web框架，通过rails可以快速的搭建起一个成型的网站，能够根据你的命令自动生成大量ruby脚本完成所需功能，简化开发流程。

###RVM and Bundler?

两个ruby包（gem）版本管理控制工具，用来解决gem版本混乱问题，保持应用gem版本的一致工具。

##搭环境

### Ubuntu

发现用了很久的11.04的软件源已经不再被支持了，很多软件无法安装，只好换了个LTS版，用12.04表示现阶段一切正常。

### 清除不能用的版本

如果现在已经不正常了就清理干净重新开始吧

    sudo apt-get remove --purge ruby-rvm ruby
    sudo rm -rf /usr/share/ruby-rvm /etc/rmvrc /etc/profile.d/rvm.sh
    rm -rf ~/.rvm* ~/.gem/ ~/.bundle*

### 安装RVM

先把依赖关系解决了

    sudo apt-get update
    sudo apt-get install -y \
      git \
      build-essential \
      curl \
      wget

安装RVM

    curl -L https://get.rvm.io | bash -s stable

把RVM脚本添加到bashrc中

    echo "[[ -s '${HOME}/.rvm/scripts/rvm' ]] && source '${HOME}/.rvm/scripts/rvm'" >> ~/.bashrc

### 安装Ruby

同样先解决依赖

    sudo apt-get install -y \
      build-essential \
      openssl \
      libreadline6 \
      libreadline6-dev \
      curl \
      git-core \
      zlib1g \
      zlib1g-dev \
      libssl-dev \
      libyaml-dev \
      libxml2-dev \
      libxslt-dev \
      autoconf \
      libc6-dev \
      ncurses-dev \
      automake \
      libtool \
      bison \
      subversion \
      pkg-config \
      sqlite3 \
      libsqlite3-dev

通过RVM安装 Ruby
    
    curl -L https://get.rvm.io | bash -s stable --ruby

检查安装是否成功

    source ~/.rvm/scripts/rvm
    rvm reload
    rvm use default
    ruby --version

这时候应该就能看到版本号了。

###解决天朝gem无法安装问题

如果你一直gem install 没有反应且在国内的话有可能就是GFW的问题了。最简单的解决方案是把软件源换成大淘宝的国内镜像。

    gem sources -a http://ruby.taobao.org/  

多种多样的解决方案可以参考[解决Rubygems被墙，GEM无法更新](http://www.cnblogs.com/varlxj/archive/2011/10/16/2211004.html)。

###安装bundler和rails

    gem install bundler --no-ri --no-rdoc
    gem install rails -v 3.2.13

这时候你运行
    
    rails -v

应该就能看到版本号了。

##建网站

命令行下

    rails new first_app

基本的代码就生成好了。
直接命令行下

    rails server

可能提示

    execJs: 'Could not find a JavaScript runtime' but execjs AND therubyracer are in Gemfile

在Gemfile中加入两行代码

    gem 'execjs'
    gem 'therubyracer', :platforms => :ruby

命令行下

    bundle install
    rails server

提示绑定到了0.0.0.0:3000，就可以在浏览器浏览你的第一个网站了。

##上线

之前的网站只能在本机上看怎么让他到糊脸上上给别人看呢，有一个叫[heroku](https://www.heroku.com/)的网站提供这个服务，可以通过git将本地网站传到heroku，由heroku展示你的网站。

###注册账号
没啥好说的

###搭建Heroku部署环境

安装Heroku gem

    gem install heroku

生成ssh密钥

    heroku login

###上传
创建heroku项目
在网站源文件目录下

    heroku create

加当前代码加入git库中

    git init
    git add .
    git commit -m "first commit"

传到heroku

    git push heroku master

然后再

    heroku open

就可以打开浏览器访问到你的网站了。    
