#!/bin/bash
if [[ -f /usr/local/Ascend/version.info ]];then
	version=`cat /usr/local/Ascend/version.info`
	echo "feature.node.kubernetes.io/cann-version=${version#*=}"
else
	echo "feature.node.kubernetes.io/cann-version=unknow"
fi

