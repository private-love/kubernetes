#! /bin/bash
#Description: 宕机后，启动服务脚本。慎用


# init env

umask 022

PATH="/sbin:/usr/sbin:/bin:/usr/bin"
export PATH

# Get a sane screen width
[ -z "${COLUMNS:-}" ] && COLUMNS=80

[ -z "${CONSOLETYPE:-}" ] && CONSOLETYPE="`/sbin/consoletype`"

#if [ -f /etc/sysconfig/i18n -a -z "${NOLOCALE:-}" ] ; then
#  . /etc/profile.d/lang.sh
#fi

# Read in our configuration
if [ -z "${BOOTUP:-}" ]; then
  if [ -f /etc/sysconfig/init ]; then
      . /etc/sysconfig/init
  else
    # This all seem confusing? Look in /etc/sysconfig/init,
    # or in /usr/doc/initscripts-*/sysconfig.txt
    BOOTUP=color
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \\033[0;39m"
    LOGLEVEL=1
  fi
  if [ "$CONSOLETYPE" = "serial" ]; then
      BOOTUP=serial
      MOVE_TO_COL=
      SETCOLOR_SUCCESS=
      SETCOLOR_FAILURE=
      SETCOLOR_WARNING=
      SETCOLOR_NORMAL=
  fi
fi

# status
RETVAL=0

echo_success() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "["
  [ "$BOOTUP" = "color" ] && $SETCOLOR_SUCCESS
  echo -n $"  OK  "
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "]"
  echo -ne "\r"
  return 0
}
echo_failure() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "["
  [ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
  echo -n $"FAILED"
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "]"
  echo -ne "\r"
  return 1
}

#添加启动服务
echo 'start httpd '
/opt/ci123/apache-2.4.16/bin/httpd -k start
RETVAL=$?
[ $RETVAL -eq 0 ] && echo_success

#echo 'starting nginx'
#/opt/ci123/nginx/sbin/nginx -c /opt/ci123/nginx/conf/nginx.conf
#RETVAL=$?
#[ $RETVAL -eq 0 ] && echo_success

echo 'start haproxy'
/opt/ci123/haproxy-1.6.3/sbin/haproxy -D -f /opt/ci123/haproxy-1.6.3/conf/haproxy.conf -p /opt/ci123/haproxy-1.6.3/logs/haproxy.pid -sf 143846
RETVAL=$?
[ $RETVAL -eq 0 ] && echo_success

#echo -n 'start keepalived'
#/etc/init.d/keepalived start
#RETVAL=$?
#[ $RETVAL -eq 0 ] && echo_success || echo_failure

echo 'starting mysqld '
/etc/init.d/mysqld restart

echo 'mount nfs filesystem'
sh /opt/nfs/mountnew.sh
#mount -t nfs 192.168.0.99:/data2/static5_img /opt/nfs/nfs5
#mount -t nfs 192.168.0.99:/data2/ci123userimage /opt/nfs/ci123userimage

echo 'start add arp info'
arp -s 192.168.1.13 14:18:77:5D:4D:FE

echo -n 'start nrpe '
/opt/ci123/nagios/bin/nrpe -d -c /opt/ci123/nagios/etc/nrpe.cfg
RETVAL=$?
[ $RETVAL -eq 0 ] && echo_success || echo_failure

echo -n 'start zabbix_agentd '
/opt/ci123/zabbix/sbin/zabbix_agentd -c /opt/ci123/zabbix/etc/zabbix_agentd.conf
RETVAL=$?
[ $RETVAL -eq 0 ] && echo_success || echo_failure


echo -n 'start salt'
/usr/bin/python2.6 /usr/bin/salt-minion -d
RETVAL=$?
[ $RETVAL -eq 0 ] && echo_success || echo_failure

echo 'sync time'
ntpdate asia.pool.ntp.org && hwclock -w

##备注:开机启动服务统计
#crond 3:启用
#iptables 3:启用
#irqbalance 3:启用
#lvm2-monitor 3:启用
#network 3:启用
#qpidd 3:启用
#rsyslog 3:启用
#salt-minion 3:启用
#snmpd 3:启用
#sshd 3:启用
#sysstat 3:启用
#udev-post 3:启用
#xinetd 3:启用

