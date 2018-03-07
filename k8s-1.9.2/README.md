```
安装Kubernetes-1.9.2
一、简介
docker.sh  安装docker17.03.2，kubeadm,kubectl,kubelet；
install.sh  主脚本，安装集群；
interface.sh  判断keepalived绑定网卡类型；
keepalived.sh 安装keepalived；
kubernetes1.9.2/ 必须的rpm包以及镜像。下载地址链接：https://pan.baidu.com/s/1Ij2uEjE2FfvnQ-LtyOdZ5Q 密码：hbfq
二、开始（提前密钥登陆配置好）
1、安装集群
root@0-238 k8s-1.9.2]# sh install.sh 

Do you want to install kubernetes-1.9.2? [master/node]: master

Do you want to install keepalived? [y/n]: y

Do you want to install keepalived,role? [master/backup]: master

Please put in keepalived level! [80~200/Default: 100]: 120
Please input keepalived VIP: 192.168.0.221

Do you want to install DB ETCD? [y/n]: y

Please input master number(Default: 3): 5

Do you want to add node? (y/n) : y

Please input node number,you want to add? ( choose:1~5000 ) : 5

What network plug-in do you want to install for Kubernetes? [flannel/calico]: calico
Please input number 1 master ip: 192.168.0.1
Please input number 2 master ip: 192.168.0.2
Please input number 3 master ip: 192.168.0.3
Please input number 4 master ip: 192.168.0.4
Please input number 5 master ip: 192.168.0.5
Please input number 1 node ip: 192.168.0.6
Please input number 2 node ip: 192.168.0.7
Please input number 3 node ip: 192.168.0.8
Please input number 4 node ip: 192.168.0.9
Please input number 5 node ip: 192.68.0.1258
input error! Please put in correct IP####IP输入不合法会报错要求重新输入
Please input number 5 node ip: 192.168.0.10
2、选择安装普通node（加入已有的集群）
[root@0-238 k8s-1.9.2]# sh install.sh 

Do you want to install kubernetes-1.9.2? [master/node]: node
Please input anyone master ip: 192.168.2.4569
input error! Please put in correct IP
Please input anyone master ip: 192.168.0.40
三、附
查看加入master的token值的命令：kubeadm token create --print-join-command
查看登陆kubernetes-dashboard的web的token：kubectl describe -n kube-system secret/`kubectl -n kube-system get secret|grep 'admin-user-token'|awk '{print $1}'`
四、原理

1、安装docker等k8s基础软件；

2、keepalived实现宕机自动切换；

四、原理
1、安装docker等k8s基础软件；
2、keepalived实现宕机自动切换；
3、搭建https etcd集群；
4、kubeadm初始化和基础服务的安装（网络组件、kubernetes-dashboard、heapster、influxdb、grafana）。
```
