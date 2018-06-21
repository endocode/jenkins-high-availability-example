#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source "${DIR}/conf.env"



yum check-update -y
yum update -y


yum install wget curl git nano -y


groupadd --gid 1024 "${PLATFORM_USER_GROUP}"
adduser --uid 1024 --gid 1024 "${PLATFORM_USER_NAME}"
echo "${PLATFORM_USER_NAME}:${PLATFORM_USER_PW}" | chpasswd
echo "chef ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers.d/${PLATFORM_USER_NAME}"
