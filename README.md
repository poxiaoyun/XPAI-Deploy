## XPAI安装说明

### 安装部署概述

本仓库安装XPAI整体流程遵循如下：

安装k8s集群（pre-install.k8s）-> 01.plugin/installer -> 01.plugin/kubegems -> 01.plugin/其余插件 ->
02.install_minio -> nvidia/gpu-operator -> 03.xpai 



### K8S集群安装


设置环境变量

```
#设置sealos默认存储位置
export SEALOS_RUNTIME_ROOT=/data/.sealos 
#设置sealos仓库数据存储位置
export SEALOS_DATA_ROOT=/data/sealos 
#关闭数据传输时md5校验
export SEALOS_SCP_CHECKSUM=false
```

安装集群

```
sealos run docker.io/labring/kubernetes:v1.25.6 docker.io/labring/helm:v3.12.0 docker.io/labring/calico:3.24.6 --masters $ip -e criData=/data/containerd
```

安装持久化卷

```
sealos run  docker.io/labring/openebs:v3.9.0  -e HELM_OPTS="--set localprovisioner.basePath=/data/openebs/localpv \
--set ndm.enabled=false \
--set ndmOperator.enabled=false \
--set localprovisioner.deviceClass.enabled=false \
--set localprovisioner.hostpathClass.isDefaultClass=true"
```

### 导入XPAI镜像

XPAI 全栈离线包

```
sealos pull registry.cn-hangzhou.aliyuncs.com/xiaoshiai/xpai-stack:1.24.6
sealos run registry.cn-hangzhou.aliyuncs.com/xiaoshiai/xpai-stack:1.24.6
```

XPAI 扩展离线包

```
sealos pull registry.cn-hangzhou.aliyuncs.com/xiaoshiai/xpai-extension:1.24.6
sealos run registry.cn-hangzhou.aliyuncs.com/xiaoshiai/xpai-extension.1.24.6
```
### 安装KubeGems

```
cd 01.plugin

kubectl apply -f installer.yaml
kubectl apply -f kubegems.yaml

# 等待kubegems正常运行
sleep 300

kubectl apply -f metrics-server.yaml
kubectl apply -f monitor.yaml
kubectl apply -f gateway.yaml
kubectl apply -f prometheus-node-exporter.yaml
```

### 安装minio


```
bash 02.install_minio.sh
```


### 安装nvidia控制器

```
cd nvidia 
kubectl apply -f operator.yaml
```

> 涉及到驱动问题，请看help文件



### 安装XPAI

```
kubectl apply -f 03.xpai.yaml
```

## 备注

### Ubuntu关闭APT自动更新

```
$ dpkg-reconfigure unattended-upgrades

debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. at /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 78.)
debconf: falling back to frontend: Readline
Configuring unattended-upgrades
-------------------------------

Applying updates on a frequent basis is an important part of keeping systems secure. By default, updates need
to be applied manually using package management tools. Alternatively, you can choose to have this system
automatically download and install important updates.

Automatically download and install stable updates? [yes/no] no

Replacing config file /etc/apt/apt.conf.d/20auto-upgrades with new version

$ cat /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";

## 禁用 unattended-upgrades 服务
systemctl stop unattended-upgrades
systemctl disable unattended-upgrades
```
