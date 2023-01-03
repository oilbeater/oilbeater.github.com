---
layout:	post
title:	"nginx 配置从零开始"
date:	2014-12-28 21:30:55
tags:
- 技术
- nginx
---

作为一个 nginx 的初学者记录一下从零起步的点滴。

## 基本概念 ##

Nginx 最常的用途是提供反向代理服务，那么什么反向代理呢？正向代理相信很多大陆同胞都在这片神奇的土地上用过了，原理大致如下图：

![](http://oilbeater.qiniudn.com/reverseproxy.png)

代理服务器作为客户端这边的中介接受请求，隐藏掉真实的客户，向服务器获取资源。如果代理服务器在长城外的话还能顺便帮助我们实现翻越长城的目的。而反向代理顾名思义就是反过来代理服务器作为服务器的中介，隐藏掉真实提供服务的服务器，原理大致如下图：

![](http://oilbeater.qiniudn.com/proxy.png)

这么做当然不是为了实现翻越长城，而是为了实现安全和负载均衡等一系列的功能。所谓安全指客户端的请求不会直接落到内网的服务器上而是通过代理做了一层转发，在这一层就可以实现安全过滤，流控，防 DDOS 等一系列策略。而负载均衡指我们可以水平扩展后端真正提供服务的服务器数量，代理按规则转发请求到各个服务器，使得各个服务器的负载接近均衡。

而 nginx 就是目前流行的这样一个反向代理服务。

## 安装 ##

在 Ubuntu 下，可以舍去编译安装的过程，直接 apt-get

    sudo apt-get install nginx

安装好之后可以直接通过：
    
    sudo service nginx start

来启动 nginx 服务，nginx 默认设置了 80 端口的转发，我们可以再浏览器访问 http://locallhost 来进行检查。

## 初始配置 ##

nginx 的默认配置文件位于


    /etc/nginx/nginx.conf

学习配置最好的方式，就是从例子入手，我们先不看其他的配置，直接看和 nginx 默认页面相关的配置。在配置文件中有一行：

    include /etc/nginx/sites-enabled/*;

这一行加载了一个外部的配置文件，sites-enabled 文件夹下只有一个 default 文件，这个外部的配置文件就是负责我们 nginx 的默认代理。将配置的内容缩水后，得到下面几行：


    server {
        server_name localhost;
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;

        root /usr/share/nginx/html;
        index index.html index.htm;
    
        location / {
        try_files $uri $uri/ =404;
        }
    }

一个大型的网站通常会有很多下属的站点，有各自的服务器提供相应的服务，在 nginx 中我们可以通过一个叫虚拟主机的概念来将这些不同的服务配置隔离，这就是上面配置中的 server 的含义。举例来说 google 旗下有翻译和学术两款产品我们就可以在 nginx 的配置文件中配置两个 server，server_name 分别为 translate.google.com 和 scholar.google.com，这样的话不同的 url 请求就会对应到 nginx 相应的设置，转发到不同的后端服务器上。这里的 server_name 是和客户端 http 请求中的 host 行进行匹配的。

本例中 server_name 为 localhost，这就是为什么我们可以在浏览器通过 localhost 访问到页面的配置。下面两个 listen 分别对应了 ipv4 和 ipv6 下的监听端口如果设为 8080，那么我们就只能通过 localhost：8080 来访问到默认页面了。

default_server 的含义是指如果有其他 http 请求的 host 在 nginx 中不存在设置的话那么就用这个 server 的配置来处理。比如我们去访问 127.0.0.1 那么也会落到这个 server 来处理。

每个 url 请求都会对应的一个服务，nginx 进行处理转发或者是本地的一个文件路径，或者是其他服务器的一个服务路径。而这个路径的匹配是通过 location 来进行的。我们可以将 server 当做对应一个域名进行的配置，而 location 是在一个域名下对更精细的路径进行配置。

在这里 location 匹配 / 开始的所有请求，即 localhost 下的 /xxx 或者 /yyy 都要走下面的配置,除了这种简单粗暴的匹配，nginx 也支持正则和完全相等及其他的精细匹配方式。而 try_files 意思是 nginx 会按照接下来的顺序去访问文件，将第一个匹配的返回。比如你去请求 localhost/test,他会去寻找 /test 文件，找不到再去找 /test/ 再找不到就返回一个 404。此外我们还可以在 location 的配置里用 proxy_pass 实现反向代理和负载均衡，不过这个最简单的配置并没有涉及。

其中 root 是指将本地的一个文件夹作为所有 url 请求的根路径。比如用户请求了一个 localhost/test,那么 nginx 就会去需找 /usr/share/nginx/html 文件夹下的 test 文件返回。

而 index 就是默认的访问页面了，当我们访问 localhost 时，他会自动按顺序寻找 root 文件路径下的 index.html 和 index.htm 将第一个找到的结果返回。

## location 进阶配置 ##

上面的配置只是将用户的 url 映射到本地的文件，并没有实现传说中的反向代理和负载均衡（当然 nginx 做静态文件的分发也是想到的厉害），下面我们就来进一步配置 location 看看怎么实现。

配置起来很简单比如我要将所有的请求到转移到真正提供服务的一台机器的 8080 端口，只要这样：

    location / {
        proxy_pass 123.34.56.67:8080;
    }

这样所有的请求就都被反向代理到 123.34.56.67 去了。这样我们反向代理的功能是实现了，可是就能代理到一台服务器上哪有什么负载均衡呀？这就要用到 nginx 的 upstream 模块了。

    upstream backend {
        ip_hash;    
        server backend1.example.com;
        server backend2.example.com;
        server backend3.example.com;
        server backend4.example.com;
    }
    location / {
        proxy_pass http://backend;
    }

我们在 upstream 中指定了一组机器，并将这个组命名为 backend，这样在 proxy_pass 中只要将请求转移到 backend 这个 upstream 中我们就实现了在四台机器的反向代理加负载均衡。其中的 ip_hash 指明了我们均衡的方式是按照用户的 ip 地址进行分配。

要让配置生效，我们不必重启 nginx 只需要 reload 配置即可。

    sudo service nginx reload


## 总结 ##

以上是最简单的通过 nginx 实现静态文件转发、反向代理和负载均衡的配置。在 nginx 中所有的功能都是通过模块来实现的，比如当我们配置 upstream 时是对 upstream 模块，而 server 和 location 是在 http core 模块，其他的还有流控的 limt 模块，邮件的 mail 模块，https 的 ssl 模块。他们的配置都是类似的可以再 nginx 的[模块文档](http://wiki.nginx.org/Modules)中找到详细的配置说明。




