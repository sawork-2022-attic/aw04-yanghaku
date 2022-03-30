# Report

## Change Log

1. 完善前后端, 实现所有按钮的功能和对应的controller
2. 实现使用jib构建镜像webpos:uncached (没有缓存版本)
3. 配置haproxy的脚本与docker-compose的配置文件, 能够实现一步部署: ```deploy/run.sh scale_num``` 即可开启```scale_num```个水平扩展集群(haproxy是在宿主机运行的).
4. 使用redis集群做会话的共享
5. 实现redis集群自动部署, 并且与原先webpos的部署整合
6. 实现通过环境变量控制缓存的开启, 构建webpos:v0.2.0镜像
7. 脚本整合, 能够通过参数控制三种情况的搭建, 如 ```deploy/run.sh web=2 redis=1 cache=true```

接下来要做的:
1. 当前只实现了1个redis的情况, redis在docker下创建集群的脚本还未成功, 需要修改
2. 实现三个类别的测试

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

