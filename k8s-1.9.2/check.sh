#/bin/bsah
###########检测etcd#############
function etcd () {
etcdctl --endpoints=https://192.168.1.146:2379 --cert-file=/data/k8s/ssl/etcd/etcd.pem --ca-file=/data/k8s/ssl/kubernetes/ca.pem --key-file=/data/k8s/ssl/etcd/etcd-key.pem cluster-health
etcdctl --endpoints=http://192.168.1.146:2389 cluster-health
}
#############检测pod和网络#############
function pod () {
nginx=`kubectl get pod -o wide|grep nginx-ds`
if [ ! -n "$nginx" ]
then 
cat > nginx-ds.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-ds
  labels:
    app: nginx-ds
spec:
  type: NodePort
  selector:
    app: nginx-ds
  ports:
  - name: http
    port: 80
    targetPort: 80

---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: nginx-ds
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  template:
    metadata:
      labels:
        app: nginx-ds
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF
kubectl create -f nginx-ds.yml
     echo -e '\033[31m creating nginx ds \033[0m'
     echo -e '\033[31m please wait 1 minute \033[0m'
     sleep 60
else echo -e '\033[32m nginx ds  has create \033[0m'
kubectl get pod -o wide|grep nginx-ds|grep -v Running
if [ $? != 0 ]
then echo -e '\033[32m nginx ds running,now start checking \033[0m'
else echo -e '\033[31m please check nginx ds \033[0m'
     exit 0
fi
###check pod ip
fi
nodeip=`kubectl get pod -o wide|grep nginx-ds|awk '{print $7}'`
podip=`kubectl get pod -o wide|grep nginx-ds|awk '{print $6}'`
for i in $nodeip
do
   echo -e '\033[32m node '$i' \033[0m'
   for ip in $podip
   do
        packetsreceived=`ssh $i ping -c 1 $ip -W 1|grep received|awk '{print $4}'`
        if [[ $packetsreceived == 1 ]]
        then echo -e ''$i' connect to '$ip' \033[32msuccess\033[0m'
        else echo -e ''$i' connect to '$ip' \033[31mfailed\033[0m'
        fi
   done
done
}
etcd
pod
