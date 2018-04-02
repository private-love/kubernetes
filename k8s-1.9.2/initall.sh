#!/bin/bash
servicelist=("etcd.service" "etcd-calico.service" "kube-apiserver.service" "kube-controller-manager.service" "kubelet.service" "kube-proxy.service" "kube-scheduler.service" "docker.service" "keepalived.service")
function stop () {
for i in ${servicelist[@]}
do 
	systemctl status $i|grep running
	if [ $? == 0 ]
	then
		systemctl stop $i && echo -e ''$i' is \033[32mstop success\033[0m'
	fi
done
}
function check () {
for i in ${servicelist[@]}
do
	l=`systemctl is-enabled $i`
	if [ $l == "enabled" ]
	then 
		systemctl status $i|grep running
		[ $? == 0 ] && echo -e ''$i' is \033[32mrunning\033[0m' || echo -e ''$i' is \033[31mnot running\033[0m'
	fi
done
ips=("192.168.1.146" "192.168.1.147" "192.168.1.148" )
for i in ${ips[@]}
do
etcdctl --endpoints=https://$i:2379 --cert-file=/data/k8s/ssl/etcd/etcd.pem --ca-file=/data/k8s/ssl/kubernetes/ca.pem --key-file=/data/k8s/ssl/etcd/etcd-key.pem cluster-health|grep unhealthy
[ $? == 1 ] && echo -e ''$i'  \033[32metcd healthy\033[0m'
etcdctl --endpoints=http://$i:2389 cluster-health|grep unhealthy
[ $? == 1 ] && echo -e ''$i'  \033[32metcd-calico healthy\033[0m'
done
}
function start () {
for i in ${servicelist[@]}
do
        l=`systemctl is-enabled $i`
        if [ $l == "enabled" ]
        then
                systemctl status $i|grep running
                [ $? == 0 ] || systemctl start $i && echo -e ''$i' is \033[32mrunning\033[0m'
        fi
done
/opt/ci123/nrpe-3.2.1/bin/nrpe -c /opt/ci123/nrpe-3.2.1/etc/nrpe.cfg -d
}
function rsynctoall () {
dir=`pwd`
node=`kubectl get nodes|grep -v NAME|awk '{print $1}'`
for i in $node
do
	ifconfig|grep $i
	if [ $? != 0 ]
	then 
		rsync initall.sh $i:$dir
		echo -e ''rsync initall.sh to $i:$dir'  \033[32msuccess\033[0m'
	else
		continue
	fi
done
}
if [ "$1" = "start" ]; then
    start
elif [ "$1" = "check" ]; then
    check
elif [ "$1" = "stop" ]; then
    stop
elif [ "$1" = "rsync" ]; then
    rsynctoall
else
    printf "Usage: ./init.sh {stop|check|start|rsync}\n"
fi
