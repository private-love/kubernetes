INTERFACEall=`ls /etc/sysconfig/network-scripts/ifcfg*|awk -F 'cfg-' '{print $2}'|awk -F ':' '{print $1}'`
for i in $INTERFACEall
do
ifconfig|grep RUNNING|grep BROADCAST|grep $i
if [ $? == 0 ]
then  INTERFACE=$i
localip=`cat /etc/sysconfig/network-scripts/ifcfg-$INTERFACE|grep IPADDR|awk -F '=' '{print $2}'`
echo $INTERFACE
else continue
fi
done
for ((i=0; i<=9; i ++))
do
KEEPlabel=$INTERFACE:$i
ifconfig|grep "$INTERFACE:$i"
if [ $? != 0 ]
then    KEEPLABEL=$INTERFACE:$i
        echo $KEEPLABEL
        break
else continue
fi
done
