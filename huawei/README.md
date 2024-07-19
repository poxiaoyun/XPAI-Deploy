## 华为晟腾910B服务器安装

### 1.安装前准备

- 所有机器时钟同步
- 安装机对集群所有节点ssh免密登录

#### 操作系统信息

- NAME="EulerOS"
- VERSION="2.0 (SP10)"
- ID="euleros"
- VERSION_ID="2.0"
- PRETTY_NAME="EulerOS 2.0 (SP10)"

### 2.系统初始化

#### 配置ansible inventory

```
cd 01.ascend/ansible

cat hosts
[test]
<IP地址>

#测试
ansible -i hosts test -m ping
```

#### 安装Ascend驱动

```
ansible-playbook -i hosts install-driver-firmware.yaml
```

> 安装完成后重启服务器

```
ansible-playbook -i hosts node-features-ascend.yaml
ansible-playbook -i hosts install-docker-runtime.yaml
ansible-playbook -i hosts before-install-deviceplugin.yaml
```
##### hccn配置npu ip

在每个晟腾服务器上运行如下命令

> 需要规划一个IP地址范围，专门用于NPU设备。这些IP地址应该是您网络中未被使用的，并且最好在一个单独的子网中
> 分配IP地址：为每个NPU设备分配一个唯一的IP地址。通常，这些地址会按照NPU设备的索引号顺序分配。

```
hccn_tool -i 0 -ip -s address 192.168.100.100 netmask 255.255.255.0
hccn_tool -i 1 -ip -s address 192.168.100.101 netmask 255.255.255.0
hccn_tool -i 2 -ip -s address 192.168.100.102 netmask 255.255.255.0
hccn_tool -i 3 -ip -s address 192.168.100.103 netmask 255.255.255.0
hccn_tool -i 4 -ip -s address 192.168.100.104 netmask 255.255.255.0
hccn_tool -i 5 -ip -s address 192.168.100.105 netmask 255.255.255.0
hccn_tool -i 6 -ip -s address 192.168.100.106 netmask 255.255.255.0
hccn_tool -i 7 -ip -s address 192.168.100.107 netmask 255.255.255.0
```

### 3.安装XPAI平台

按照正常流程安装

### 5.安装ascend依赖环境

```
helm install --create-namespace -n mindx-dl xpai 02.nfd

cd 03.manifest/ascend-device-plugin
kubectl apply -f .

cd 03.manifest/ascend-hccl-controller
kubectl apply -f .

cd 03.manifest/ascend-npu-exporter
kubectl create ns npu-exporter
kubectl apply -f .
```

配置containerd配置
```
version = 2
root = "/data/containerd"
state = "/run/containerd"
oom_score = 0

[grpc]
  address = "/run/containerd/containerd.sock"
  uid = 0
  gid = 0
  max_recv_message_size = 16777216
  max_send_message_size = 16777216

[debug]
  address = "/run/containerd/containerd-debug.sock"
  uid = 0
  gid = 0
  level = "warn"

[timeouts]
  "io.containerd.timeout.shim.cleanup" = "5s"
  "io.containerd.timeout.shim.load" = "5s"
  "io.containerd.timeout.shim.shutdown" = "3s"
  "io.containerd.timeout.task.state" = "2s"

[plugins]
  [plugins."io.containerd.runtime.v1.linux"]
    no_shim = false
    runtime = "/usr/local/Ascend/Ascend-Docker-Runtime/ascend-docker-runtime"
    runtime_root = ""
    shim = "containerd-shim"
    shim_debug = false

  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "sealos.hub:5000/pause:3.8"
    max_container_log_line_size = -1
    max_concurrent_downloads = 20
    disable_apparmor = true
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
      default_runtime_name = "runc"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runtime.v1.linux"
          runtime_engine = ""
          runtime_root = ""
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
          [plugins."io.containerd.grpc.v1.cri".registry.configs."sealos.hub:5000".auth]
            username = "admin"
            password = "passw0rd"
```

6. 设置node标签

```
#标记910b服务器
kubectl label node <node>  accelerator=huawei-Ascend910
kubectl label node <node> feature.node.kubernetes.io/ascend-accelerator=huawei-Ascend910

#标记dls节点
kubectl label node <node>  masterselector=dls-master-node
kubectl label node <node>  workerselector=dls-worker-node
```
