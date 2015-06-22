---
layout:	post
title:	"分布式系统断电自恢复"
date:	2015-03-22 15:40:55
category:	"system"
---

机房断电后各种服务该怎么恢复呢？

首先当然是恢复供电机器重启，但是上面的服务该怎么办，派人去手工重启么？



一个服务还好，但是一个机房这么多服务敲命令要累死了，怎么办？写个脚本执行启动命令，放到开机启动脚本 rc.local 里好了。

可是掉的不止你一个服务，可能你启动依赖的服务也掉了，启动的还比你晚，启动根本就起不来怎么办？

一个简单粗暴的方式，不断重试就好了。在 cron.d 下面放个任务每分钟执行一次，一看服务进程不存在就尝试重启。一方面不考虑依赖问题，另一方面还顺道解决了服务 crash 后的自恢复。

可实际中有的服务在依赖没启动时是可以起来的，但是工作会不正常，而且不能再依赖启动之后自动恢复，还是需要手动重启。严重的时候不正常的服务还会导致依赖它的服务异常，这该怎么办呢？

看样子似乎是无法摆脱依赖顺序而随心所欲的启动程序。那么就只能所有的服务各自汇报自己的服务上下游给一个人，然后那个人画一个启动流程图，告诉大家先干这个，再干那个么？嗯，一个如果机房里业务固定还好，如果不固定，今天加一个新应用，明天减一个旧应用，那么图就要改一遍。应用改个依赖，图又要改一遍，而且要这个画图的人时刻了解服务依赖的变化，想想就头疼。那么就没有个自动化的方法么？

可以先参考一个类似的问题，systemd 是如何解决单机上开机程序之间的依赖问题。程序之间的依赖本质上来讲就是需要进行进程间的通信，而开机程序的进程间通信主要是通过 socket 和 dbus 来完成。systemd 的做法是预先建立好这些 socket 和 dbus，这样当一个程序发起通信时即使依赖程序还没启动完成，至少 socket 是打开的，可以先把请求 queue 住。这样发起请求的程序就会等待，而等依赖就绪就会处理这个请求，源程序就可以继续运行。这样理论上讲大多数情况下我们都不需要考虑程序间依赖，只需要把所有程序启动起来就好了。

实现一个分布式的 systemd 还是有些困难的，但是这种思想很有启发。我们可以脱离集中化控制的思想，把分布式系统的重启任务分布式的解决。分布式服务之间的依赖本质上也是进程间通信，而且绝大多数都是 tcp/udp 请求。简单的来说一个服务只需要判断他的上游服务是否 ready 来判断自己要不要启动，每个服务只需要在自己的机器上验证这个条件，不断地重试，整个服务就可以自动的按照顺序自发启动。

这样的话我们就无需一个集中式的管理，每个服务自己梳理自己的依赖来进行自启动即可。除了简单的 tcp 探测也可以对 web 服务进行 http 的探测来进一步保证依赖的可用性。

在 github 上新建了个项目可以简单的通过一个 yaml 配置文件描述进程名，依赖和启动脚本，即可自动生成自启动脚本，大家有兴趣的可以去尝试一下 [https://github.com/oilbeater/Autoheal](https://github.com/oilbeater/Autoheal)。

把 README 抄录入下

# Autoheal
A simple script that auto restart distribute service from power cut or service crash.

# Where it come?
All services will crash after a power cut.When power comes back, services recovery may face these problems:

1. No auto restart and service will not work
2. Service restarts before dependencies getting ready and restart may crash.
2. Service restarts before dependencies getting ready and the service can not work correctly.

What we want is ordered restart.But as more and more services connect together,it's complex to find and maintain a global order. What we provide here is a simple way to deal with th problem.

# How it work?

A centralized restart system may hard to implement,but same effect can be achieved by other method.Let's have a look at how systemd deal with the process dependency at startup time.

Processe dependency is caused by inter-process communication (IPC) in essence. Socket and dbus are two main way of IPC during startup time.What systemd dose are pre-create these sockets and dbus,parallelizd all process and queued the request before corresponding process get ready.The process will be blocked when dependency is not ready and continue work as dependency starts to work and finishes the request.By this way most time no order need to be explicitly pointed out.

Inspired by systemd, we can deal with distribute services restart distributly.Every service checks its directly dependency and start as they are ready.No more global order is needed,different service can restart automatically.Most service are connected by tcp socket or an application layer http protocal,Linux command nc and curl can be used to check these services.

This program Autoheal provide an easy way to generate a script combining checking process liveness,checking dependencies and restarting process together.
# Running

1. Installing the pyyaml dependency

        sudo pip install pyyaml
    
2. Writing conf.yaml as following example:

        nginx:                                                                # process 1
            pname: nginx                                                      # use progess name to check process exist
            script: sudo -u admin /home/admin/cai/bin/nginx-proxy -s restart  # restart the process
        web_service:                                                          # process 2
            pid_file: /home/admin/web_server/conf/.web_server.pid             # use pid file to check process exist
            dep:
                - name: nginx                                                 # check tcp dependency
                  host: 127.0.0.1
                  port: 80
                - name: middleware                                            # check http dependency
                  url: http://middleware.host.com/check.htm
            script: sudo -u admin /home/admin/web_server/bin/startup.sh
  
3. Generate the restart script:
  
        sh generate.sh >> restart.sh
  
4. Add a cron task to run restart.sh regularly.You can create a file in /etc/cron.d like this
  
        * * * * * root sh /home/admin/startup.sh > /dev/null 2>&1
      
    Note about the user privilege to start the process correctly.
