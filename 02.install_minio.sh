#!/bin/bash
kubectl create ns kubegems-pai
helm install -n kubegems-pai xpai-minio minio
