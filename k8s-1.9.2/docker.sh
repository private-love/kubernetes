systemctl disable firewalld;systemctl stop firewalld
swapoff -a
sed 's/.*swap.*/#&/' /etc/fstab
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p /etc/sysctl.conf
yum install -y yum-utils device-mapper-persistent-data lvm2 gcc openssl-devel libnl libnl-devel libnfnetlink-devel
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -y
yum makecache fast
yum install kubernetes1.9.2/docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch.rpm -y
yum install docker-ce-17.03.2.ce-1.el7.centos -y
sed -i "s/dockerd/dockerd --registry-mirror=https:\/\/y48nmauv.mirror.aliyuncs.com --log-driver=json-file --log-opt max-size=100m --log-opt max-file=10/g" /usr/lib/systemd/system/docker.service
systemctl daemon-reload;systemctl enable docker;systemctl start docker
for i in kubernetes1.9.2/*.tar;do docker load -i $i;done
for i in kubernetes1.9.2/calico*.tar.gz;do docker load -i $i;done
yum install kubernetes1.9.2/kubeadm-1.9.2-0.x86_64.rpm kubernetes1.9.2/kubelet-1.9.2-0.x86_64.rpm kubernetes1.9.2/kubernetes-cni-0.6.0-0.x86_64.rpm kubernetes1.9.2/kubectl-1.9.2-0.x86_64.rpm -y
sed -i "s/systemd/cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload;systemctl enable kubelet;systemctl start kubelet
