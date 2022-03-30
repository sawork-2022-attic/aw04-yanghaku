#!/bin/bash

SHELL_FOLDER=$(dirname $(readlink -f "$0"))

cached_docker_compose_file="$SHELL_FOLDER/docker-compose-cached.yml"
uncached_docker_compose_file="$SHELL_FOLDER/docker-compose-uncached.yml"

docker_compose_yml_file=$cached_docker_compose_file # 默认开启的是带缓存版本的集群
haproxy_template_cfg="$SHELL_FOLDER/haproxy-template.cfg"
haproxy_cfg="$SHELL_FOLDER/haproxy.cfg"

# 解析第一个参数, 水平扩展的个数
if [ ! -n "$1" ] || [ -z $1 ]; then
	echo "usage run.sh scale_number [true/false]"
	exit 0
fi

expr $1 "+" 0 &> /dev/null
if [ $? -ne 0 ]; then
	echo "scale_number must be a number"
	exit 0
elif [ $1 -le 0 ]; then
	echo "scale_number must greater than 0"
	exit 0
fi

# 解析第二个参数, 是否开启缓存的版本. (默认是true)
if [ -n "$2" ] && [ ! -z "$2" ]; then
	if [ "$2" == "false" ]; then
		docker_compose_yml_file=$uncached_docker_compose_file
	elif [ "$2" == "true" ]; then
		docker_compose_yml_file=$cached_docker_compose_file
	else
		echo "usage run.sh scale_number [true/false]"
		exit 0
	fi
fi


scale=$1
echo "scale number is $scale"

echo "docker-compose file is $docker_compose_yml_file"
docker_compose="docker-compose -f $docker_compose_yml_file"

echo "start docker compose"
$docker_compose up -d --scale webpos=$scale
if [ $? -ne 0 ]; then
	echo "docker-compose up fail"
	exit 1
else
	echo "docker-compose up success"
	$docker_compose ps
fi

# 指定捕获ctrl+c, 完成清理工作
trap 'SIGINT_handler' INT
SIGINT_handler(){
	echo -e "\nquit"
	$docker_compose down
	rm -f $haproxy_cfg
	exit 0
}

# 根据扩展个数生成相应的haproxy的配置文件

if [ ! -f "$haproxy_template_cfg" ];then
	echo "file $haproxy_template_cfg not exist"
	SIGINT_handler
fi

cp $haproxy_template_cfg $haproxy_cfg
for i in $(seq 1 $scale); do
	server_name=deploy_webpos_$i

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

echo "generated haproxy config file:"
cat $haproxy_cfg

echo -e "\nrunning haproxy......   ctrl^c to stop"
haproxy -f $haproxy_cfg || SIGINT_handler
