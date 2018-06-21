#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env



# src: https://wiki.centos.org/HowTos/GlusterFSonCentOS
# src: https://wiki.jenkins.io/display/JENKINS/Installing+Jenkins+on+Red+Hat+distributions



groupadd --gid "${JENKINS_USER_ID}" \
         --system "${JENKINS_USER_NAME}"
adduser --uid "${JENKINS_USER_ID}" \
        --gid "${JENKINS_USER_ID}" \
        --no-create-home \
        --system "${JENKINS_USER_NAME}"

yum install -y java

curl --output "/etc/yum.repos.d/jenkins.repo" \
     --location \
     --silent \
     "https://pkg.jenkins.io/redhat-stable/jenkins.repo"
rpm --import "https://jenkins.io/redhat/jenkins-ci.org.key"
yum install -y jenkins

# NOTE: it seems that for whatever reason the default is enabled, but since the cluster logic takes
# care of the jenkins service, it needs to be disabled, especially in case of reboot
systemctl disable jenkins


yum install -y centos-release-gluster
yum install -y glusterfs glusterfs-fuse attr


systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-port=${JENKINS_WEB_PORT}/tcp --permanent  # jenkins web interface
firewall-cmd --zone=public --add-port=${JENKINS_JNLP_PORT}/tcp --permanent  # JNLP
firewall-cmd --zone=public --add-port=33848/udp --permanent # UDP, used by jenkins-swarm client
firewall-cmd --reload

mkdir -p "${JENKINS_HOME_PATH}"

chown -R "${JENKINS_USER_NAME}:${JENKINS_USER_NAME}" "${JENKINS_HOME_PATH}"
find "${JENKINS_HOME_PATH}" -type d -exec chmod 750 {} \;
find "${JENKINS_HOME_PATH}" -type f -exec chmod 640 {} \;
