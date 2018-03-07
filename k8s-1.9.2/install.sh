#!/bin/bash
########################################安装docker、kubectl、kubeadm、kubelet#################################
function yumrpm () {
for ((i=1; i<=$Masternum; i ++))
do
rsync -avr /root/wlx/k8s-1.9.2 ${ips[$i]}:/root/wlx/
ssh ${ips[$i]} "cd /root/wlx/k8s-1.9.2/;sh docker.sh"
done
}
##################################################安装keepalived集群############################################
function keepalived () {
for ((i=1; i<=$Masternum; i ++))
do
ssh ${ips[$i]} "cd /root/wlx/k8s-1.9.2/;sh keepalived.sh"
done
for ((i=1; i<=$Masternum; i ++))
do
INTERFACE=`ssh ${ips[$i]} "sh /root/wlx/k8s-1.9.2/interface.sh"|tail -2|head -1`
KEEPLABEL=`ssh ${ips[$i]} "sh /root/wlx/k8s-1.9.2/interface.sh"|tail -1`
cat << EOF > keepalived$i.conf
global_defs {
   notification_email {
     acassen@firewall.loc
     failover@firewall.loc
     sysadmin@firewall.loc
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 192.168.200.1
   smtp_connect_timeout 30
   router_id LVS_DEVEL_123
}

vrrp_instance VI_1 {
    state BACKUP
    interface $INTERFACE
    virtual_router_id 123
    priority $KEEPALIVEDlevel
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        $KEEPALIVEDVIP label $KEEPLABEL
    }
}
EOF
[ $i == 1 ] && sed -i "s/BACKUP/$KEEPALIVEDROLE/g" keepalived$i.conf
KEEPALIVEDlevel=`expr $KEEPALIVEDlevel - 1`
rsync keepalived$i.conf ${ips[$i]}:/etc/keepalived/keepalived.conf
ssh ${ips[$i]} "systemctl daemon-reload;systemctl start keepalived;systemctl enable keepalived"
done
}
###########################################安装master集群#############################################
function master () {
cat << EOF > config.yaml
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
etcd:
  endpoints:
  - https://${ips[1]}:2379
  - https://${ips[2]}:2379
  - https://${ips[3]}:2379
  - https://${ips[4]}:2379
  - https://${ips[5]}:2379
  caFile: /etc/etcd/ssl/ca.pem 
  certFile: /etc/etcd/ssl/etcd.pem 
  keyFile: /etc/etcd/ssl/etcd-key.pem
  dataDir: /var/lib/etcd
networking:
  podSubnet: 10.244.0.0/16
kubernetesVersion: 1.9.2
api:
  advertiseAddress: "$KEEPALIVEDVIP"
#token: "b99a00.a144ef80536d4344"
token: "178abb.0df2a92c8e9c7526" 
tokenTTL: "0s"
apiServerCertSANs:
- $KEEPALIVEDVIP
- ${ips[1]}
- ${ips[2]}
- ${ips[3]}
- ${ips[4]}
- ${ips[5]}
featureGates:
  CoreDNS: true
#imageRepository: "devhub.beisencorp.com/google_containers"
EOF
sed -i '/192\.168\.0\.0/d' config.yaml
for ((i=1; i<=$Masternum; i ++))
do
if [ $i == 1 ]
then
	rsync config.yaml ${ips[$i]}:/root/wlx/k8s-1.9.2/
	ssh ${ips[$i]} "kubeadm init --config /root/wlx/k8s-1.9.2/config.yaml"
	ssh ${ips[$i]} "mkdir -p /root/.kube;cp /etc/kubernetes/admin.conf /root/.kube/config"
	for ((y=2; y<=$Masternum; y ++))
	do
	ssh ${ips[$i]} "rsync -avr /root/wlx/k8s-1.9.2/config.yaml ${ips[$y]}:/root/wlx/k8s-1.9.2/"
	ssh ${ips[$i]} "rsync -avr /etc/kubernetes/pki ${ips[$y]}:/etc/kubernetes/"
	done
else 
ssh ${ips[$i]} "kubeadm init --config /root/wlx/k8s-1.9.2/config.yaml"
ssh ${ips[$i]} "mkdir -p /root/.kube;cp /etc/kubernetes/admin.conf /root/.kube/config"
fi
done
}
##############################################检查输入的IP合法性################################################
function check_ip () {
    local IP=$1
    VALID_CHECK=$(echo $1|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $1|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
        if [ $VALID_CHECK == "yes" ]; then
            return 0
        else
        echo -e "\033[31minput error! Please put in correct IP\033[0m"
            return 1
        fi
    else
        echo -e "\033[31minput error! Please put in correct IP\033[0m"
        return 1
    fi
}
##################################################安装etcd集群####################################################
function etcd () {
if [ -f kubernetes1.9.2/cfssl ]	
then mv kubernetes1.9.2/cfssl* /usr/local/bin/
else
	wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
	chmod +x cfssl_linux-amd64
	mv cfssl_linux-amd64 /usr/local/bin/cfssl
	wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
	chmod +x cfssljson_linux-amd64
	mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
	wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
	chmod +x cfssl-certinfo_linux-amd64
	mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
fi
cat >  ca-config.json <<EOF
{
"signing": {
"default": {
  "expiry": "8760h"
},
"profiles": {
  "kubernetes": {
    "usages": [
        "signing",
        "key encipherment",
        "server auth",
        "client auth"
    ],
    "expiry": "8760h"
  }
}
}
}
EOF
cat >  ca-csr.json <<EOF
{
"CN": "kubernetes",
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
  "C": "CN",
  "ST": "NanJing",
  "L": "NanJing",
  "O": "k8s",
  "OU": "System"
}
]
}
EOF
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
ls ca*
case $Masternum in
1)
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ips[1]}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "NanJing",
      "L": "NanJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
;;
2)
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ips[1]}",
    "${ips[2]}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "NanJing",
      "L": "NanJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
;;
3)
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ips[1]}",
    "${ips[2]}",
    "${ips[3]}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "NanJing",
      "L": "NanJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
;;
4)
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ips[1]}",
    "${ips[2]}",
    "${ips[3]}",
    "${ips[4]}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "NanJing",
      "L": "NanJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
;;
5)
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ips[1]}",
    "${ips[2]}",
    "${ips[3]}",
    "${ips[4]}",
    "${ips[5]}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "NanJing",
      "L": "NanJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
;;
esac
#sed -i '/192\.168\.0\.0/d' etcd-csr.json
cfssl gencert -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes etcd-csr.json | cfssljson -bare etcd

ls etcd*
case $Masternum in
    1)
    clusterdir=etcd-k8s1=https://${ips[1]}:2380
    ;;
    2)
    clusterdir=etcd-k8s1=https://${ips[1]}:2380,etcd-k8s=https://${ips[2]}:2380
    ;;
    3)
    clusterdir=etcd-k8s1=https://${ips[1]}:2380,etcd-k8s2=https://${ips[2]}:2380,etcd-k8s3=https://${ips[3]}:2380
    ;;
    4)
    clusterdir=etcd-k8s1=https://${ips[1]}:2380,etcd-k8s2=https://${ips[2]}:2380,etcd-k8s3=https://${ips[3]}:2380,etcd-k8s4=https://${ips[4]}:2380
    ;;
    5)
    clusterdir=etcd-k8s1=https://${ips[1]}:2380,etcd-k8s2=https://${ips[2]}:2380,etcd-k8s3=https://${ips[3]}:2380,etcd-k8s4=https://${ips[4]}:2380,etcd-k8s5=https://${ips[5]}:2380
    ;;
esac
for ((i=1; i<=$Masternum; i ++))
do
ssh ${ips[$i]} "mkdir -p /etc/etcd/ssl"
rsync etcd.pem etcd-key.pem ca.pem ${ips[$i]}:/etc/etcd/ssl/
mkdir -p /var/lib/etcd
cat > etcd$i.service <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/local/bin/etcd \\
  --name=etcd-k8s$i \\
  --cert-file=/etc/etcd/ssl/etcd.pem \\
  --key-file=/etc/etcd/ssl/etcd-key.pem \\
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \\
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \\
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \\
  --initial-advertise-peer-urls=https://${ips[$i]}:2380 \\
  --listen-peer-urls=https://${ips[$i]}:2380 \\
  --listen-client-urls=https://${ips[$i]}:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls=https://${ips[$i]}:2379 \\
  --initial-cluster-token=etcd-cluster-0 \\
  --initial-cluster=$clusterdir \\
  --initial-cluster-state=new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
rsync etcd$i.service ${ips[$i]}:/etc/systemd/system/etcd.service
[ -f kubernetes1.9.2/etcd-v3.1.10-linux-amd64.tar.gz ] || wget http://github.com/coreos/etcd/releases/download/v3.1.10/etcd-v3.1.10-linux-amd64.tar.gz -O kubernetes1.9.2/
tar -zxvf kubernetes1.9.2/etcd-v3.1.10-linux-amd64.tar.gz
rsync etcd-v3.1.10-linux-amd64/etcd* ${ips[$i]}:/usr/local/bin
ssh ${ips[$i]} "systemctl daemon-reload;systemctl enable etcd;systemctl start etcd"
done
 etcdctl \
  --endpoints=https://${ips[1]}:2379  \
  --ca-file=/etc/etcd/ssl/ca.pem \
  --cert-file=/etc/etcd/ssl/etcd.pem \
  --key-file=/etc/etcd/ssl/etcd-key.pem \
  cluster-health
}
#################################################在master执行时添加node节点###########################################################
function nodeinstall () {
KUBEADMjion=`kubeadm token create --print-join-command`
for ((i=1; i<=$nodenum; i ++))
do
rsync docker.sh ${nodeips[$i]}:/root/wlx/
ssh ${nodeips[$i]} "sh /root/wlx/docker.sh"
ssh ${nodeips[$i]} "$KUBEADMjion"
done
}
###############################################node节点上执行加入已存在的k8s集群##################################################
function Nodeinstall () {
KUBEADMjion=`ssh $masterIP "kubeadm token create --print-join-command"`
$KUBEADMjion

}
#####################################################输入集群必须的参数############################################################
while :
do
        echo
        read -p "Do you want to install kubernetes-1.9.2? [master/node]: " kubernetesrole
        if [ "$kubernetesrole" != 'master' -a "$kubernetesrole" != 'node' ];then
                echo -e "\033[31minput error! Please only input 'master' or 'node'\033[0m"
        else
                if [ "$kubernetesrole" == 'master' ]
		then
#########################keepalived参数
		while :
		do
		echo
		read -p "Do you want to install keepalived? [y/n]: " Keepalived_yn
		if [ "$Keepalived_yn" != 'y' -a "$Keepalived_yn" != 'n' ];then
		    echo -e "\033[31minput error! Please only input 'y' or 'n'\033[0m"
		else
		if [ "$Keepalived_yn" == 'y' ];then
		while :
		do
		        echo
		        read -p "Do you want to install keepalived,role? [master/backup]: " KEEPALIVEDrole
		        if [ "$KEEPALIVEDrole" != 'master' -a "$KEEPALIVEDrole" != 'backup' ];then
		                echo -e "\033[31minput error! Please only input 'master' or 'backup'\033[0m"
		        else
		                if [[ "$KEEPALIVEDrole" == 'master' || "$KEEPALIVEDrole" == 'backup' ]]
		                then 
				[ "$KEEPALIVEDrole" == 'master' ] && KEEPALIVEDROLE=MASTER || KEEPALIVEDROLE=BACKUP
				     while :
		                     do
		                        echo
		                        KEEPALIVEDLEVEL=100
		                        read -p "Please put in keepalived level! [80~200/Default: 100]: " KEEPALIVEDlevel
		                        [ -z "$KEEPALIVEDlevel" ] && KEEPALIVEDlevel=$KEEPALIVEDLEVEL
		                        if [ $KEEPALIVEDlevel -eq 100 >/dev/null 2>&1 -o $KEEPALIVEDlevel -gt 79 >/dev/null 2>&1 -a $KEEPALIVEDlevel -lt 201 >/dev/null 2>&1 ]
		                        then
		                        break
		                        else
		                        echo -e "\033[31minput error! Input range: 100,80~200\033[0m"
		                        fi
		                     done
		                fi
		        break
		        fi
		done
		echo
		while true; do
		    read -p "Please input keepalived VIP: " KEEPALIVEDVIP
		    check_ip $KEEPALIVEDVIP
		    [ $? -eq 0 ] && break
		done
		fi
		break
		fi
		done
#########################etcd参数
		while :
		do
		        echo
		        read -p "Do you want to install DB ETCD? [y/n]: " Etcd_yn
		        if [ "$Etcd_yn" != 'y' -a "$Etcd_yn" != 'n' ];then
		                echo -e "\033[31minput error! Please only input 'y' or 'n'\033[0m"
		        else
		                break
		        fi
		done
##############################master、node数目参数
		while :
		do
		        echo
			masternum=3
		        read -p "Please input master number(Default: $masternum): " Masternum
			[ -z "$Masternum" ] && Masternum=$masternum
		        if [ $Masternum -eq 3 >/dev/null 2>&1 -o $Masternum -gt 0 >/dev/null 2>&1 -a $Masternum -lt 6 >/dev/null 2>&1 ];then
		                break
		        else
		                echo -e "\033[31minput error! Input range: ,1~5\033[0m"
		        fi
		done
		while :
		do
			echo
			read -p "Do you want to add node? (y/n) : " node_yn
			if [ "$node_yn" != 'y' -a "$node_yn" != 'n' ];then
			    echo -e "\033[31minput error! Please only input 'y' or 'n'\033[0m"
			else
			if [ "$node_yn" == 'y' ];then
	                while :
	                do
	                        echo
	                        Nodenum=0
	                        read -p "Please input node number,you want to add? ( choose:1~5000 ) : " nodenum
	                        [ -z "$nodenum" ] && nodenum=$Nodenum
	                        if [ $nodenum -eq 0 >/dev/null 2>&1 -o $nodenum -gt 0 >/dev/null 2>&1 -a $nodenum -lt 5001 >/dev/null 2>&1 ];then
	                                break
	                        else
	                                echo -e "\033[31minput error! Input range: ,1~5000\033[0m"
	                        fi
	                done
			break
			else break
			fi
			fi
		done
		while :
		do
	        echo
	        read -p "What network plug-in do you want to install for Kubernetes? [flannel/calico]: " networktype
	        if [ "$networktype" != 'flannel' -a "$networktype" != 'calico' ];then
	                echo -e "\033[31minput error! Please only input 'flannel' or 'calico'\033[0m"
		else break
		fi
		done
#		else 
		fi
		break
	fi
done
################################master、nodeIP信息
if [ "$kubernetesrole" == 'master' ]
then
	ips=(0 "192.168.0.0" "192.168.0.0" "192.168.0.0" "192.168.0.0" "192.168.0.0")
	for ((i=1; i<=$Masternum; i ++))
	do
		while :
		do
		    read -p "Please input number $i master ip: " masterip
		    check_ip $masterip
		    [ $? -eq 0 ] && ips[$i]=$masterip && break
		done
	done
	if [ "$node_yn" == 'y' ];then
	for ((i=1; i<=$nodenum; i ++))
	do
	        while :
		do
	            read -p "Please input number $i node ip: " nodeip
	            check_ip $nodeip
	            [ $? -eq 0 ] && nodeips[$i]=$nodeip && break
	        done
	done
	fi
else
        while : 
	do
            read -p "Please input anyone master ip: " masterIP
            check_ip $masterIP
            [ $? -eq 0 ] && break
        done
fi
##################################################################start install######################################################
for ((i=1; i<=$Masternum; i ++))
do
echo ${ips[$i]}
done
if [ "$kubernetesrole" == 'master' ]
then
	yumrpm
	[ "Keepalived_yn" == "y" ] && keepalived
	[ "Etcd_yn" == "y" ] && etcd
	master
	if [ "$node_yn" == 'y' ];then
	nodeinstall
	fi
	sed -i "s/192\.168\.0\.136/$KEEPALIVEDVIP/g" kubernetes1.9.2/yaml/heapster.yaml
	[ "$networktype" == 'flannel' ] && kubectl create -f kubernetes1.9.2/yaml/kube-flannel.yaml || kubectl create -f kubernetes1.9.2/yaml/calico.yaml
	sleep 60
	kubectl create -f kubernetes1.9.2/yaml/base/
else
	sh docker.sh
	Nodeinstall
fi
######################################################
#printf "Usage: ./install.sh {s|c|s|r|}\n"
