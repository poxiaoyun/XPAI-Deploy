### 1. too many openfiles

临时解决方法

```
#执行
sudo sysctl -w fs.inotify.max_user_watches=2099999999
sudo sysctl -w fs.inotify.max_user_instances=2099999999
sudo sysctl -w fs.inotify.max_queued_events=2099999999


# 修改/etc/security/limits.conf
* - nofile 6553500
* - nproc 6553500
root - nofile 1048576
root - nproc 1048576
```

重启机器

### 2. 在线安装NVIDIA驱动

默认情况下gpu-operator会自动编译安装GPU驱动，期间会同步和下载APT镜像源来更新编译环境，请保持网络的畅通。

如果需要自行安装NVIDIA驱动，请在安装XPAI前进行。按照如下操作方式（Ubuntu）安装驱动

- 查看当前系统支持的驱动版本

```
$ ubuntu-drivers list --gpgpu

nvidia-driver-470
nvidia-driver-470-server
nvidia-driver-535
nvidia-driver-535-open
nvidia-driver-535-server
nvidia-driver-535-server-open
nvidia-driver-550
nvidia-driver-550-open
nvidia-driver-550-server
nvidia-driver-550-server-open
```

- 安装驱动,推荐使用535版本

```
$ ubuntu-drivers install --gpgpu nvidia:535-server
$ apt install nvidia-utils-535-server


# 如果GPU带了Nvlink或者NvSwitch，则继续安装
$ apt install nvidia-fabricmanager-535 libnvidia-nscq-535
```

- 驱动安装完成后，重启主机

- 禁用插件自动安装GPU驱动

通过自行安装NVIDIA驱动，需要在安装gpu-operator插件时将driver禁用，如下

```
  values:
    driver:
      enabled: false
```

### 3. 离线安装NVIDIA GPU驱动

NVIDIA驱动由gpu-operator自动安装，离线场景下需采用预编译安装模式

在gpu-operator的plugin配置中加入如下配置

```
  values:
    driver:
      usePrecompiled: true
      version: 525
```

此时operator则会根据当前主机的内核版本创建预编译镜像，这里可查看所有支持的预编译安装的操作系统发行版和对应的内核版本[https://explore.ggcr.dev/?repo=nvcr.io%2Fnvidia%2Fdriver]

> 安装包已离线nvcr.io/nvidia/driver:525-5.15.0-78-generic-ubuntu22.04, 建议使用Ubuntu22.04.3 TLS ,内核版本为5.15.0-78-generic的发行版
