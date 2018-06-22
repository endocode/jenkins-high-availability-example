#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env



sed -i \
    -e 's/EXTERNAL_LOAD_BALANCER_PORT/'"${EXTERNAL_LOAD_BALANCER_PORT}"'/g' \
    -e 's/PRIVATE_NETWORK_SLASH24_PREFIX/'"${PRIVATE_NETWORK_SLASH24_PREFIX}"'/g' \
    -e 's/JENKINS_WEB_PORT/'"${JENKINS_WEB_PORT}"'/g' \
    -e 's/JENKINS_JNLP_PORT/'"${JENKINS_JNLP_PORT}"'/g' \
    ./haproxy.cfg_template
cp ./haproxy.cfg_template /etc/haproxy/haproxy.cfg
cp ./haproxy_template /etc/default/haproxy

systemctl enable haproxy
systemctl start haproxy
