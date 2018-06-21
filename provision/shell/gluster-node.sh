#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env



# src: https://wiki.centos.org/HowTos/GlusterFSonCentOS



yum install -y centos-release-gluster
yum install -y glusterfs gluster-cli glusterfs-libs glusterfs-server


systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-port=24007-24008/tcp --permanent
# NOTE: for each brick there needs to be an additional port to get opened, starting at 24009
firewall-cmd --zone=public --add-port=24009/tcp --permanent
# NOTE: for native gluster-clients
firewall-cmd --zone=public --add-port=49152-49251/tcp --permanent
# NOTE: for nfs clients
#firewall-cmd --zone=public --add-port=38465-38469/tcp --add-port=111/tcp --add-port=2049/tcp --permanent
#firewall-cmd --zone=public --add-service=nfs --permanent
firewall-cmd --reload

systemctl enable glusterd
systemctl start glusterd


mkdir -p "${GLUSTER_JENKINS_BRICK_DIR}"
