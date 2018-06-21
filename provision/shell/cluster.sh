#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env



yum install -y pacemaker pcs psmisc policycoreutils-python


firewall-cmd --permanent --add-service=high-availability
firewall-cmd --reload

systemctl enable pcsd.service
systemctl start pcsd.service

#set password for corosync communication user
echo "${COROSYNC_USER_NAME}:${COROSYNC_USER_PASSWORD}" | chpasswd
