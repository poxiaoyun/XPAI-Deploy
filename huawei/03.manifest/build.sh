#!/bin/bash

set -xe

function npu-device-plugin(){
#	https://github.com/Ascend/ascend-device-plugin/blob/56adb78632bcdbcc77b3a7387eadd35ada641a93/main.go#L226
# Containerd场景下必须从环境变量中读取ASCEND_DOCKER_RUNTIME，否则NPU设备分配tmd的无效， - -！

  local file=$1/env.patch
  cat > $file <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ascend-device-plugin-daemonset
  namespace: kube-system
spec:
  template:
    spec:
      containers:
      - name: device-plugin-01
        env:
          - name: ASCEND_DOCKER_RUNTIME
            value: "True"
EOF
}

function npu-exporter-sm(){
# https://www.hiascend.com/document/detail/zh/mindx-dl/50rc2/clusterscheduling/clusterscheduling/dlug_guide_03_000138.html

    local file=$1/servicemonitor.yaml
    cat > $file << EOF
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/scrape: "true"
  labels:
    app: npu-exporter
  name: npu-exporter
  namespace: npu-exporter
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: npu-metrics
    port: 8082
    protocol: TCP
    targetPort: 8082
  selector:
    app: npu-exporter
  sessionAffinity: None
  type: ClusterIP

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    name: npu-exporter
  name: npu-exporter
  namespace: npu-exporter
spec:
  endpoints:
  - honorLabels: true
    interval: 30s
    path: /metrics
    port: npu-metrics
    relabelings:
    - action: replace
      sourceLabels:
      - __meta_kubernetes_endpoint_node_name
      targetLabel: node
    - action: replace
      sourceLabels:
      - __meta_kubernetes_pod_host_ip
      targetLabel: host_ip
  jobLabel: app
  namespaceSelector:
    matchNames:
    - npu-exporter
  selector:
    matchLabels:
      app: npu-exporter
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    prometheusrule.kubegems.io/name: ascend-record-rule
  name: ascend-record-rule
  namespace: kubegems-monitoring
spec:
  groups:
    - name: ascend
      rules:
        - record: ascend_npu_freq
          expr: |
            npu_chip_info_aicore_current_freq * on (host_ip,vdie_id) group_left(pod_name,namespace)
            container_npu_utilization
        - record: ascend_npu_hbm_used_memory
          expr: |
            npu_chip_info_hbm_used_memory * on (host_ip,vdie_id) group_left(pod_name,namespace)
            container_npu_utilization
        - record: ascend_npu_hbm_total_memory
          expr: |
            npu_chip_info_hbm_total_memory  * on (host_ip,vdie_id) group_left(pod_name,namespace)
            container_npu_utilization
        - record: ascend_npu_bandwidth_rx
          expr: |
            npu_chip_info_bandwidth_rx * on (host_ip,vdie_id) group_left(pod_name,namespace)
            container_npu_utilization
        - record: ascend_npu_bandwidth_tx
          expr: |
            npu_chip_info_bandwidth_tx * on (host_ip,vdie_id) group_left(pod_name,namespace)
            container_npu_utilization
        - record: ascend_npu_temperature
          expr: |
            npu_chip_info_temperature * on (host_ip,vdie_id) group_left(pod_name,namespace)
            container_npu_utilization
        - record: ascend_npu_power
          expr: |
            npu_chip_info_power * on (host_ip,vdie_id) group_left(pod_name,namespace)
            container_npu_utilization
EOF

    local file=$1/args.patch
    cat > $file << EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: npu-exporter
  namespace: npu-exporter
spec:
  template:
    spec:
      containers:
      - name: npu-exporter
        args: [ "umask 027;npu-exporter -port=8082 -ip=0.0.0.0  -updateTime=5
                 -logFile=/var/log/mindx-dl/npu-exporter/npu-exporter.log -logLevel=0 -containerMode=containerd" ]
EOF
}

SEP=__SEP__

# version_path="v6.0.0-RC1"
# version_path1="6.0.RC1"
# tag=v6.0.0-rc1

version_path="v5.0.0-Patch5"
version_path1="5.0.0.5"
tag=v5.0.0.5

image_repo=registry.cn-beijing.aliyuncs.com/kubegems


components=(
    "https://gitee.com/ascend/ascend-device-plugin/releases/download/${version_path}/Ascend-mindxdl-device-plugin_${version_path1}_linux-aarch64.zip"__SEP__"ascend-k8sdeviceplugin"
    "https://gitee.com/ascend/ascend-noded/releases/download/${version_path}/Ascend-mindxdl-noded_${version_path1}_linux-aarch64.zip"__SEP__"noded"
    "https://gitee.com/ascend/ascend-hccl-controller/releases/download/${version_path}/Ascend-mindxdl-hccl-controller_${version_path1}_linux-aarch64.zip"__SEP__"hccl-controller"
    "https://gitee.com/ascend/ascend-npu-exporter/releases/download/${version_path}/Ascend-mindxdl-npu-exporter_${version_path1}_linux-aarch64.zip"__SEP__"npu-exporter"
)


echo "" > ${version}.txt
for component in "${components[@]}";do
    url="${component%%__SEP__*}"
    img="${component#*__SEP__}"
    filename=`basename $url`
    prefix="${url%%/releases*}"
    taill="${url#*download/}"
    cname=`basename $prefix`
    version=`dirname $taill`
    targetdir=${cname}_${version}
    echo $filename
    echo $targetdir
    sleep 2
    if [[ ! -f $filename ]];then
        wget $url
    fi
    if [[ ! -d $targetdir ]];then
        unzip $filename -d $targetdir
    fi
    #pushd $targetdir
    #    docker buildx build --pull=false --platform linux/arm64 -t ${image_repo}/$img:$tag . --push
    #popd
    if [[ $cname == "ascend-npu-exporter" ]];then
        npu-exporter-sm $targetdir
    fi
    if [[ $cname == "ascend-device-plugin" ]];then
        npu-device-plugin $targetdir
    fi

    echo ${image_repo}/$img:$tag >> ${version}.txt
done

