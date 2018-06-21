#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env



SWARM_VERSION="3.13"
INSTALL_PATH="/etc/jenkins-swarm"
JAR_LOCATION="${INSTALL_PATH}/swarm-client.jar"
SERVICE_FILE="jenkins-swarm.service"



yum install -y patch openssl-devel.x86_64 gcc gcc-c++ kernel-devel make


yum install java -y

mkdir -p "${INSTALL_PATH}"
curl --output "${JAR_LOCATION}" \
     --location \
     --silent \
     "https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_VERSION}/swarm-client-${SWARM_VERSION}.jar"


cp ./${SERVICE_FILE} "/etc/systemd/system/${SERVICE_FILE}"

systemctl daemon-reload
systemctl enable ${SERVICE_FILE}
systemctl start ${SERVICE_FILE}
