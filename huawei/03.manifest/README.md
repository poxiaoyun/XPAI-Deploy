### 注意事项
安装ascend组件前务必先修改Containerd的配置

```yaml
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
