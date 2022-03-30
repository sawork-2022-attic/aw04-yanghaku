# Report

## Change Log

1. 完善前后端, 实现所有按钮的功能和对应的controller
2. 实现使用jib构建镜像webpos:uncached (没有缓存版本)
3. 配置haproxy的脚本与docker-compose的配置文件, 能够实现一步部署: ```deploy/run.sh scale_num``` 即可开启```scale_num```个水平扩展集群(haproxy是在宿主机运行的).

下一步:
1. 实现会话的共享
2. 实现缓存的管理, 并且构建镜像webpos:cached (有缓存版本), 同时更新配置相应的docker-compose配置文件, 更新```run.sh```, 增加第二个参数(true/false)是否开启带缓存的集群
3. 三种情况的测试


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

