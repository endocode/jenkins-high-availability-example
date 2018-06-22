#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env



yum install haproxy -y



systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-port=${EXTERNAL_LOAD_BALANCER_PORT}/tcp --permanent  # jenkins web interface
firewall-cmd --zone=public --add-port=${JENKINS_JNLP_PORT}/tcp --permanent  # JNLP
firewall-cmd --reload
