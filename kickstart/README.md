kickstart
```
1、os + os 优化  >> ks_os6_8.cfg/ks_os7_4.cfg（系统安装完之后的基础依赖的安装，以及基础优化）
2、1+ lanmp      >> ks_lanmp6_8.cfg/ks_lanmp7_4.cfg（搭建lanmp的基础环境，包含系统基础优化）
3、1+db          >> ks_db6_8.cfg/ks_db7_4.cfg（搭建数据库环境，包含系统基础优化，不包含Apache，nginx等web服务器）
4、1+k8s         >> ks_k8s7_4.cfg（包含系统优化和一些k8s集群的服务基础包的安装,系统装完后执行install-k8s-2.sh脚本就能安装集群，执行之前需要修改脚本中的集群IP）
```
pxelinux.cfg
```
文件位置：tftpboot/pxelinux.cfg/default
此文件主要配置多种安装环境的选择：
centos6.8/centos7.4/db/lanmp/k8s
```
