#!/bin/bash

SHELL_FOLDER=$(dirname $(readlink -f "$0"))

# 配置文件常量
redis_yml_file="$SHELL_FOLDER/docker-compose-redis.yml"
web_yml_file="$SHELL_FOLDER/docker-compose-web.yml"
haproxy_template_cfg="$SHELL_FOLDER/haproxy-template.cfg"
haproxy_cfg="$SHELL_FOLDER/haproxy.cfg"
redis_conf_file="$SHELL_FOLDER/redis.conf"

# 配置集群的前缀
export COMPOSE_PROJECT_NAME="webpos"

# 检查配置文件是否存在
if [ ! -f "$haproxy_template_cfg" ];then
	echo "file $haproxy_template_cfg not exist"
	exit -1
fi
if [ ! -f "$redis_yml_file" ];then
	echo "file $redis_yml_file not exist"
	exit -1
fi
if [ ! -f "$web_yml_file" ];then
	echo "file $web_yml_file not exist"
	exit -1
fi

# 解析参数 (redis=, web=, cache=)   默认值: (redis=3, web=1, cache=false)
redis_num=3
web_num=1
cache_enable="false"

print_help(){
	echo "usage $0 [redis=number] [web=number] [cache=true/false]"
	echo "default value: redis=$redis_num, web=$web_num, cache=$cache_enable"
	exit -1
}

# 开始解析
for arg in $*; do
	if [ "${arg:0:3}" == "web" ]; then	# parse the web
		val=${arg##*=}
		if [ ! -n "$val" ] || [ -z $val ]; then
			echo "scale_number for web cannot be null"
			print_help
		fi
		expr $val "+" 0 &> /dev/null
		if [ $? -ne 0 ]; then
			echo "scale_number for web must be a number"
			print_help
		elif [ $val -le 0 ]; then
			echo "scale_number for web must greater than 0"
			print_help
		fi
		web_num=$val

	elif [ "${arg:0:5}" == "redis" ]; then	# parse the redis
		val=${arg##*=}
		if [ ! -n "$val" ] || [ -z $val ]; then
			echo "scale_number for redis cannot be null"
			print_help
		fi
		expr $val "+" 0 &> /dev/null
		if [ $? -ne 0 ]; then
			echo "scale_number for redis must be a number"
			print_help
		elif [ $val -le 2 ]; then
			echo "scale_number for redis must greater than 2"
			print_help
		fi
		redis_num=$val

	elif [ "${arg:0:5}" == "cache" ]; then  # parse the cache
		val=${arg##*=}
		if [ "$val" != "true" ] && [ "$val" != "false" ]; then
			echo "cache value must be true or false"
			print_help
		else
			cache_enable=$val
		fi

	else
		echo "invalid argmuent $arg"
		print_help
	fi

done

echo "parse success! (redis=$redis_num, web=$web_num, cache=$cache_enable)"


# 注册信号, 捕获ctrl+c, 完成清理工作
trap 'SIGINT_handler' INT
SIGINT_handler(){
	echo -e "\nquit"

	export COMPOSE_FILE=$web_yml_file
	docker-compose down

	export COMPOSE_FILE=$redis_yml_file
	docker-compose down

	if [ -f $haproxy_cfg ]; then
		rm -f $haproxy_cfg
	fi
	exit 0
}

#------------------------------------------------启动redis集群-----------------------
echo "creating redis cluster"

# 设置部署的集群使用的配置文件
export COMPOSE_FILE=$redis_yml_file

# 设置redis的yml的环境变量
export REDIS_CONF=$redis_conf_file

# 启动
docker-compose up -d --scale redis=$redis_num || SIGINT_handler
echo "create redis cluster success"

# 获取redis集群每个节点的ip, 传给webpos的集群
redis_ip_list=""
cluster_command="redis-cli --cluster create "
for i in $(seq 1 $redis_num); do
	server_name=${COMPOSE_PROJECT_NAME}_redis_$i

	# 获取ip地址
	ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $server_name)

	if [ $? -ne 0 ]; then
		# 失败就退出 (可能会因为docker权限问题不能执行查询命令)
		echo "get ip address for $server_name fail"
		SIGINT_handler
	fi

	ip="$ip:6379"
	if [ "$redis_ip_list" == "" ]; then # 如果是第一个元素就直接赋值, 否则中间加逗号隔开
		redis_ip_list=$ip
	else
		redis_ip_list="$redis_ip_list,$ip"
	fi
	cluster_command="$cluster_command $ip" # 创建集群的命令都用逗号隔开
done

echo "redis ip address list = $redis_ip_list"

# 在第一个docker节点执行创建命令
(docker exec ${COMPOSE_PROJECT_NAME}_redis_1 echo "yes" | $cluster_command) || SIGINT_handler

#------------------------------------------------启动webpos集群----------------------
echo "creating webpos cluster"

# 设置部署的集群的名称前缀和使用的配置文件
export COMPOSE_FILE=$web_yml_file

# 配置部署的yml里面的环境变量
export WEBPOS_VERSION="v0.2.0"
export CACHE_ENABLE=$cache_enable
export REDIS_NODES=$redis_ip_list

# 启动
docker-compose up -d --scale web=$web_num || SIGINT_handler
# echo "create webpos cluster success"


#------------------------------------------------根据webpos集群配置haproxy-------------
# 根据扩展个数生成相应的haproxy的配置文件, 先复制模板文件, 然后添加server
cp $haproxy_template_cfg $haproxy_cfg

for i in $(seq 1 $web_num); do
	server_name=${COMPOSE_PROJECT_NAME}_web_$i

	# 获取ip地址
	ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $server_name)

	if [ $? -ne 0 ]; then
		# 失败就退出 (可能会因为docker权限问题不能执行查询命令)
		echo "get ip address for $server_name fail"
		SIGINT_handler
	fi

	# 将对应的ip写到配置文件中
	echo -e "\tserver $server_name $ip:8080" >> $haproxy_cfg
done

echo "generate haproxy config file success"

#------------------------------------------------启动haproxy------------------------
echo -e "\nrunning haproxy......   ctrl^c to stop"
haproxy -f $haproxy_cfg || SIGINT_handler
