---
layout: post
title: "Gemfile入门介绍"
description: "第一次接触ruby这门语言路上碰到的障碍还是要记录一下的。"
img: "http://lh5.googleusercontent.com/-kUKhpCIDfsA/Ui06U9kkjpI/AAAAAAAAAZ0/zhk8uETi6fk/w845-h846-no/original_V0HB_527c0000272f125d.jpg"
category: 
tagline: "Hack the life"
tags: [ruby,gem]
published: true
---

主要翻译自[gemfile manual](http://gembundler.com/v1.3/man/gemfile.5.html)

Gemfile主要是用来管理ruby程序所依赖的gem，下面逐一介绍主要的配置。


###source

gem的下载源例如

    source "https://rubygems.org"
    source "http://gems.github.com"
    source "http://ruby.taobao.com"

优先级为越靠下的越高，鉴于国内的情况推荐使用第三个大淘宝的源。
    
###ruby

如果程序需要特定版本的ruby或ruby引擎，就需要指明一下例如

    ruby "1.8.7", :engine => "jruby", :engine_version => "1.6.7"

其中engine和engine_version是可选的。

###gem

   程序所依赖的gem及其版本组别等等信息，也是参数最复杂的一个关键字，下面将从简单到复杂逐一介绍。

#####name

唯一一个必选项，指明程序需要哪个gem，例如：

    gem "nokogiri"

其它选项均为可选项

#####version

制定所需gem版本例如：

    gem 'rails', '3.0.0.beta3'
    gem 'rack',  '>=1.0'
    gem 'thin',  '~>1.1'

<p>‘>=’表示大于当前版本的最新版本。</p>
<p>那么第三个~>1.1是啥意思呢，就是>=1.1且小于2.0的最新版本。~> 2.0.3就是>=2.03且小于2.1的最新版本即控制gem的版本在一个发行区间内。</p>

#####require

如果gem的main file名字和gem 的name不同需要通过require 指定，例如：

    gem 'rspec', :require => 'spec'

如果require指定为false表示在程序运行时不会自动require该gem

    gem "webmock", :require => false
    
#####group

有些gem只是开发环境下需要如wirble，有些只是测试环境需要如rspec，而有的是线上系统需要，为了节省空间和时间可以把gem分组，例如

    gem "rspec", :group => :test
    gem "wirble", :groups => [:development, :test]

这样在bundle install 时可以加入without选项指明不安装那些gem，例如

    bundle install --without development test

##### git,github,path

这几个选项都是用来指定从哪里安装gem通常是一些特殊版本或者特殊的gem，source里没有的。例如

    gem 'nokogiri', :git => 'git://github.com/tenderlove/nokogiri.git', :branch => '1.4'
    gem 'nokogiri', :path => '~/sw/gems/nokogiri'
    gem "rails", :github => "rails/rails"

其中path通常指本地一个路径，git和github可以指定一个git库并通过branch，tag，和ref指定版本库中的一个特定版本。

#####platform

指定平台相关的tem，通常是某个操作系统或某个ruby引擎下的特有gem例如：

    gem "weakling",   :platforms => :jruby
    gem "ruby-debug", :platforms => :mri_18
    gem "nokogiri",   :platforms => [:mri_18, :jruby]

###块控制语句

如group，git，path和path这类语句可以一次控制很多gem，例如：

    git "git://github.com/rails/rails.git" do
      gem "activesupport"
      gem "actionpack"
    end

    platforms :ruby do
      gem "ruby-debug"
      gem "sqlite3"
    end

    group :development do
      gem "wirble"
      gem "faker"
    end
