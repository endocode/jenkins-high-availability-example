#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env


POOL_MEMBER_HOSTNAME=${1}


# src: https://wiki.centos.org/HowTos/GlusterFSonCentOS



gluster peer probe "${POOL_MEMBER_HOSTNAME}"

sleep 10    # because previous command is async in conjunction to the following one

gluster volume create "${GLUSTER_BRICK_ID}" \
        replica 2 \
        transport tcp \
        "${POOL_MEMBER_HOSTNAME}:${GLUSTER_JENKINS_BRICK_DIR}" "$(hostname):${GLUSTER_JENKINS_BRICK_DIR}" force
gluster volume set "${GLUSTER_BRICK_ID}" storage.owner-gid "${JENKINS_USER_ID}"
gluster volume set "${GLUSTER_BRICK_ID}" storage.owner-uid "${JENKINS_USER_ID}"
gluster volume start "${GLUSTER_BRICK_ID}"
