#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env


ADDITIONAL_GLUSTER_NODES_INDEX_FILE_PATH="${1}"



nodeIP=$(ip address | grep -oP "(?:${PRIVATE_NETWORK_SLASH24_PREFIX})[\S]+(?=/)")
echo "${nodeIP}" >> ${ADDITIONAL_GLUSTER_NODES_INDEX_FILE_PATH}
