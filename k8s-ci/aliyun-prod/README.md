一、文件及使用方式介绍
```
1、admin.conf 阿里云k8s-prod 的kubeconfig文件(请向运维部提出申请) 
   a、使用方法参考第4点
   b、安装kubectl 工具

2、yaml k8s 服务调度配置文件
   a、当前目录下创建dev ， prod 目录
   b、根据需求生产预发布测试环境配置文件保存在dev ，生产环境保存在prod目录下

3、phpmyadmin-db 项目mysql数据库配置
   直接替换相关信息即可使用
```

4、mk-data-container.sh 将当前目录下文件及目录，做到镜像里面。同时，作为数据卷挂载到kubectl容器下使用

方法如下：

```bash
sh mk-data-container.sh
docker run --rm --volumes-from data docker.io/lachlanevenson/k8s-kubectl:v1.8.1 --kubeconfig /data/admin.conf create ns $namespaces
docker run --rm --volumes-from data docker.io/lachlanevenson/k8s-kubectl:v1.8.1 --kubeconfig /data/admin.conf create secret docker-registry aliyun-sec -n $namespaces --docker-server=registry.cn-hangzhou.aliyuncs.com --docker-username=nanjingruyue --docker-password=ci123asdf --docker-email=2355603226@qq.com
docker run --rm --volumes-from data docker.io/lachlanevenson/k8s-kubectl:v1.8.1 --kubeconfig /data/admin.conf create -f /data/dev/ -n $namespaces
```

二、替换参数说明
1. yaml 配置文件
```
PROJECT-NAME  项目名称替换变量
NAMESPACE   项目所属namespace
REGISTER-IMAGE 项目镜像替换变量
MYSQL_HOST  mysql数据库主机地址替换变量
MYSQL_PORT  mysql数据库端口替换变量
MYSQL_USERNAME mysql数据库用户名替换变量
MYSQL_PASSWORD mysql数据库密码替换变量，默认root密码 
MYSQL_DBNAME  mysql数据库名称
PROJECT-DOMAIN 项目域名替换变量
PROJECT-NAME-DOMAIN phpmyadmin访问域名
其它变量需求请告知chenwenping
```

三、存储问题构建镜像
```
1、目前采取nfs挂载方式，主要采取人工配置方式

可能存在新项目代码和数据库目录不存在或者容量不够等情况，请提前与运维沟通，由运维提前申请、采购、配置。

2、pv及pvc机制

a、阿里云后台申请nas盘
b、nas盘下根目录，根据项目名称，自动创建目录
c、动态生成pv、pvc 的yaml文件
d、通过kubectl 提交到k8s集群初始化好，并管理好项目
```

四、jenkins镜像构建
```
PROJECT_NAME 项目名称 代码目录 /opt/ci123/www/html/PROJECT_NAME
GIT_SOURCE_ADDR 项目代码库ssh地址
CC_EMAILS   邮件接收
NAME_SPACE k8s namespace
BASE_REGISTER_IMAGE   基础镜像
APP_REGISTER_IMAGE    包含代码的应用镜像
CALL_BACK_WEBHOOK   one-deply web hook 触发ci流程

例子：
curl -X POST --user "username:token" -s https://jenkins-ci.oneitfarm.com/job/image-auto-build/buildWithParameters -d "PROJECT_NAME=php-apache&GIT_SOURCE_ADDR=git@gitlab.oneitfarm.com:noc/wordpress.git&CC_EMAILS=cjy@corp-ci.com&NAME_SPACE=backend&BASE_REGISTER_IMAGE=registry.cn-hangzhou.aliyuncs.com/noc/php-apache:php5.6.13-apache&APP_REGISTER_IMAGE=registry.cn-hangzhou.aliyuncs.com/noc/php-apache-app:php5.6.13.3-apache&CALL_BACK_WEBHOOK=http://www.ci123.com"

```
