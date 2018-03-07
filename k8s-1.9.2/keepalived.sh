#!/bin/bash
if [ -f kubernetes1.9.2/keepalived-1.4.1.tar.gz ]
then tar -zxvf kubernetes1.9.2/keepalived-1.4.1.tar.gz
     mkdir -p /opt/ci123/keepalived-1.4.1
     ./keepalived-1.4.1/configure --prefix=/opt/ci123/keepalived-1.4.1/
     make && make install
     rsync -avr /opt/ci123/keepalived-1.4.1/etc/keepalived /etc/
     sed -i "s/\-D/\-D\ \-d\ \-S\ 5/g" /opt/ci123/keepalived-1.4.1/etc/sysconfig/keepalived
else yum install -y keepalived
     sed -i "s/\-D/\-D\ \-d\ \-S\ 5/g" /etc/sysconfig/keepalived
fi
