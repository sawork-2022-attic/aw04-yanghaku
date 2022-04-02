# Report

## 测试报告

> 使用jmeter进行的压力测试

### 垂直扩展比较

环境: 
* **1**个web容器 ( **0.1个cpu, 0.5个cpu, 1个cpu, 5个cpu, 10个cpu** )
* 3个redis集群做会话共享
* 无cache

模拟**4000**个用户的多轮并发访问, 结果汇总表格:

| cpus | pass   | fail  | average response time | min response time | max response time |
| ---- | ------ | ----- | --------------------- | ----------------- | ----------------- |
| 0.1  | 0%     | 100%  | 74041.35 ms           | -                 | 191589 ms         |
| 0.5  | 92.07% | 7.94% | 45134.39 ms           | 0                 | 140797 ms         |
| 1    | 99.96% | 0.04% | 18374.42 ms           | 0                 | 108165 ms         |
| 5    | 100%   | 0%    | 288.06 ms             | 0                 | 7034 ms           |
| 10   | 100%   | 0%    | 90.98 ms              | 0                 | 4851 ms           |

可以看到, cpu性能越好, 错误率越低, 并且时延越低.  (但是单个机器的cpu还是有上限的, 所以还是得需要水平的扩展)

> (测试的时候要临时修改一下最大文件句柄个数(```ulimit -n 65535```), 免得出现```SocketException/Non HTTP response message: Too many open files```这种错误)

### 水平扩展的比较

pending

### 数据缓存效果的分析

pending

<hr/>

## 部署

> 在完善并且构建了可配置的镜像之后, 尝试做了一个自动化部署的脚本, 实现一键部署.

### 宿主机环境依赖:

* docker
* docker-compose
* haproxy

### 命令

```bash
# 默认参数 单个web容器(web=1), redis集群内个数(redis=3), 不使用缓存(cache=false)
deploy/run.sh

# 指定多个web容器, 指定cache为false
deploy/run.sh web=10 cache=false

# 指定多个web容器, 并且开启cache
deploy/run.sh web=16 cache=true

# 任意指定
deploy/run.sh web=110 redis=120 cache=true
```

> (解析错误或者参数不合法的时候都有对应的错误处理, 并且显示帮助信息

### 搭建原理

#### webpos项目打包

通过环境变量注入redis集群的节点信息, 注入是否使用cache, 这样就可以实现一个多用了.
当前已经上传dockerhub: https://hub.docker.com/repository/docker/yanghaku/webpos , tag为v0.3.0
可以直接```docker pull yanghaku/webpos:v0.2.0```

#### 容器集群创建

1. 通过docker-compose, 创建命名空间为```webpos_webpos```的网络
2. 启动redis集群, 查询每个redis节点的ip, 然后通过第一个redis里面的```redis-cli```创建集群
3. 启动web的集群, 通过设置环境变量注入每个redis节点的ip, 是否开启缓存等
4. 查询每个web节点的ip, 生成```haproxy.cfg```, 作为代理的配置文件
5. 启动宿主机的haproxy, 监控8080端口对每个web节点做负载均衡

#### 清理

```ctrl+c```发送kill信号, ```run.sh```捕获到之后, 停止haproxy, 然后通过docker-compose关闭集群, 删除所有的容器, 删除创建的网络命名空间


### 运行效果

启动:

```bash
[yb@yb-ubuntu1804 aw04-yanghaku (main ✗)]$ deploy/run.sh web=10 cache=true

parse success! (redis=3, web=10, cache=true)
creating redis cluster
Creating network "webpos_webpos" with the default driver
Creating webpos_redis_1 ... done
Creating webpos_redis_2 ... done
Creating webpos_redis_3 ... done
create redis cluster success
redis ip address list = 172.30.0.3:6379,172.30.0.2:6379,172.30.0.4:6379
>>> Performing hash slots allocation on 3 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
M: 2766df9c651fa17079dd4159155f893c85a0f912 172.30.0.3:6379
   slots:[0-5460] (5461 slots) master
M: fa6150f84c97fd1c89c17cf1413f365e601414a9 172.30.0.2:6379
   slots:[5461-10922] (5462 slots) master
M: 4e7eff86cc210cf1fa4afec82870c51bd774167e 172.30.0.4:6379
   slots:[10923-16383] (5461 slots) master
Can I set the above configuration? (type 'yes' to accept): >>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
>>> Performing Cluster Check (using node 172.30.0.3:6379)
M: 2766df9c651fa17079dd4159155f893c85a0f912 172.30.0.3:6379
   slots:[0-5460] (5461 slots) master
M: fa6150f84c97fd1c89c17cf1413f365e601414a9 172.30.0.2:6379
   slots:[5461-10922] (5462 slots) master
M: 4e7eff86cc210cf1fa4afec82870c51bd774167e 172.30.0.4:6379
   slots:[10923-16383] (5461 slots) master
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
creating webpos cluster
Creating webpos_web_1  ... done
Creating webpos_web_2  ... done
Creating webpos_web_3  ... done
Creating webpos_web_4  ... done
Creating webpos_web_5  ... done
Creating webpos_web_6  ... done
Creating webpos_web_7  ... done
Creating webpos_web_8  ... done
Creating webpos_web_9  ... done
Creating webpos_web_10 ... done
generate haproxy config file success

running haproxy......   ctrl^c to stop
```

停止:
```bash
^C
quit
Stopping webpos_web_5  ... done
Stopping webpos_web_10 ... done
Stopping webpos_web_7  ... done
Stopping webpos_web_9  ... done
Stopping webpos_web_4  ... done
Stopping webpos_web_2  ... done
Stopping webpos_web_3  ... done
Stopping webpos_web_1  ... done
Stopping webpos_web_6  ... done
Stopping webpos_web_8  ... done
Removing webpos_web_5  ... done
Removing webpos_web_10 ... done
Removing webpos_web_7  ... done
Removing webpos_web_9  ... done
Removing webpos_web_4  ... done
Removing webpos_web_2  ... done
Removing webpos_web_3  ... done
Removing webpos_web_1  ... done
Removing webpos_web_6  ... done
Removing webpos_web_8  ... done
Network webpos_webpos is external, skipping
Stopping webpos_redis_2 ... done
Stopping webpos_redis_3 ... done
Stopping webpos_redis_1 ... done
Removing webpos_redis_2 ... done
Removing webpos_redis_3 ... done
Removing webpos_redis_1 ... done
Removing network webpos_webpos
```

<hr/>

## Change Log

1. 完善前后端, 实现所有按钮的功能和对应的controller
2. 实现使用jib构建镜像webpos:uncached (没有缓存版本)
3. 配置haproxy的脚本与docker-compose的配置文件, 能够实现一步部署: ```deploy/run.sh scale_num``` 即可开启```scale_num```个水平扩展集群(haproxy是在宿主机运行的).
4. 使用redis集群做会话的共享
5. 实现redis集群自动部署, 并且与原先webpos的部署整合
6. 实现通过环境变量控制缓存的开启, 构建webpos:v0.2.0镜像
7. 脚本整合, 能够通过参数控制三种情况的搭建, 如 ```deploy/run.sh web=2 redis=1 cache=true```
8. 部署并且测试了docker中bridge网络的集群 (**普大喜奔, 终于能跑了!**)
9. 完善webpos, 提高健壮性并且增加了日志记录时间消耗
10. (更新到0.3.0) 使用静态内部类, 防止多线程访问posDB的数据竞争以及大量访问jd的时候被ban. 确保**只有1次访问jd**, 其他的线程等待结果即可.
11. 测试

<hr/>
<hr/>
<hr/>

# WebPOS

The demo shows a web POS system , which replaces the in-memory product db in aw03 with a one backed by 京东.


![](jdpos.png)

To run

```shell
mvn clean spring-boot:run
```

Currently, it creates a new session for each user and the session data is stored in an in-memory h2 db. 
And it also fetches a product list from jd.com every time a session begins.

1. Build a docker image for this application and performance a load testing against it.
2. Make this system horizontally scalable by using haproxy and performance a load testing against it.
3. Take care of the **cache missing** problem (you may cache the products from jd.com) and **session sharing** problem (you may use a standalone mysql db or a redis cluster). Performance load testings.

Please **write a report** on the performance differences you notices among the above tasks.

