#!/bin/bash

mkdir -p kustomize

version="v5.0.0-Patch5"

create_kustomization() {
    echo "resources:" > kustomization.yaml
    ls *.yaml | grep -v 'kustomization.yaml' | xargs -I {} echo "- {}" >> kustomization.yaml
    ls *.patch > /dev/null 2>&1
    local req=$?
    if [ $req == "0" ]; then
      echo "patchesStrategicMerge:" >> kustomization.yaml
      ls *.patch | grep -v 'kustomization.yaml' | xargs -I {} echo "- {}" >> kustomization.yaml
    fi
}

pushd kustomize
    mkdir -p ascend-device-plugin
    pushd ascend-device-plugin
        ls ../../ascend-device-plugin_${version}/*.yaml ../../ascend-device-plugin_${version}/*.patch  |grep -v volcano|grep -v soc|xargs -I F cp F .
        create_kustomization
        find . -maxdepth 1 -type f -exec sed -i '' "s/accelerator/feature.node.kubernetes.io\/ascend-accelerator/g" {} +
    popd

    mkdir -p ascend-npu-exporter
    pushd ascend-npu-exporter
        ls ../../ascend-npu-exporter_${version}/*.yaml ../../ascend-npu-exporter_${version}/*.patch |grep -v soc|xargs -I F cp F .
        create_kustomization
    popd

    mkdir -p ascend-noded
    pushd ascend-noded
        ls ../../ascend-noded_${version}/*.yaml |xargs -I F cp F .
        create_kustomization
    popd

    mkdir -p ascend-hccl-controller
    pushd ascend-hccl-controller
        ls ../../ascend-hccl-controller_${version}/*.yaml |xargs -I F cp F .
        create_kustomization
    popd
    echo "resources:" > kustomization.yaml
    ls | grep -v 'kustomization.yaml' | xargs -I {} echo "- {}" >> kustomization.yaml
popd

cat > huawei-nfr.yaml << EOF
apiVersion: nfd.k8s-sigs.io/v1alpha1
kind: NodeFeatureRule
metadata:
  name: huawei-ascend-features
spec:
  rules:
    - name: "Ascend-910B"
      labels:
        ascend-accelerator: "huawei-Ascend910"
      matchFeatures:
        - feature: pci.device
          matchExpressions:
            vendor: {op: In, value: ["19e5"]}
            device: {op: In, value: ["d802"]}
    - name: "Ascend-910A"
      labels:
        ascend-accelerator: "huawei-Ascend910"
      matchFeatures:
        - feature: pci.device
          matchExpressions:
            vendor: {op: In, value: ["19e5"]}
            device: {op: In, value: ["d801"]}
    - name: "Ascend-310"
      labels:
        ascend-accelerator: "huawei-Ascend310"
      matchFeatures:
        - feature: pci.device
          matchExpressions:
            vendor: {op: In, value: ["19e5"]}
            device: {op: In, value: ["d100"]}
    - name: "Ascend-310P"
      labels:
        ascend-accelerator: "huawei-Ascend310P"
      matchFeatures:
        - feature: pci.device
          matchExpressions:
            vendor: {op: In, value: ["19e5"]}
            device: {op: In, value: ["d500"]}
EOF