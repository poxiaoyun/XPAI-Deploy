
### 安装sealos和导入镜像
```
tar zxvf sealos_4.3.7_linux_amd64.tar.gz sealos && chmod +x sealos && mv sealos /usr/bin

sealos load -i k8s.tar
sealos load -i helm.tar
sealos load -i calico.tar
sealos load -i ebs.tar

systemctl stop systemd-resolved.service
systemctl disable systemd-resolved.service
echo "nameserver 114.114.114.114" > /etc/resolv.conf
```

#### 安装Kubernetes集群

```
#设置sealos默认存储位置
export SEALOS_RUNTIME_ROOT=/data/.sealos
#设置sealos仓库数据存储位置
export SEALOS_DATA_ROOT=/data/sealos
#关闭数据传输时md5校验
export SEALOS_SCP_CHECKSUM=false


#安装kubernetes集群
export ip=<主机IP地址>
sealos run docker.io/labring/kubernetes:v1.25.6 docker.io/labring/helm:v3.12.0 docker.io/labring/calico:3.24.6 --masters $ip -e criData=/data/containerd

#安装openebs 本地数据盘
sealos run  docker.io/labring/openebs:v3.9.0  -e HELM_OPTS="--set localprovisioner.basePath=/data/openebs/localpv \
--set ndm.enabled=false \
--set ndmOperator.enabled=false \
--set localprovisioner.deviceClass.enabled=false \
--set localprovisioner.hostpathClass.isDefaultClass=true"
```
