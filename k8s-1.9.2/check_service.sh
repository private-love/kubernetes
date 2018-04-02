#!/bin/bash
servicelist=("etcd.service" "etcd-calico.service" "kube-apiserver.service" "kube-controller-manager.service" "kubelet.service" "kube-proxy.service" "kube-scheduler.service" "docker.service" "keepalived.service")
function check () {
num=0
for i in ${servicelist[@]}
do
	l=`systemctl is-enabled $i`
	if [ $l == "enabled" ]
	then 
		status=`systemctl status $i|grep running`
		[ $? == 0 ] && true[$num]=$i || error[$num]=$i
	fi
	let num++
done
ips=("192.168.1.146" "192.168.1.147" "192.168.1.148" )
#[[ -z ${error[*]} ]] &&  echo ${error[*]}
#[[ -z ${true[*]} ]] && echo ${true[*]}
if [[ ${#error[@]} != 0 ]] 
then
	echo {${error[*]}} is error
	return 2
else
	echo  OK:all service is running
	return 0
fi
}
check
