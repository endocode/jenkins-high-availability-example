#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env



# configure corosync
pcs cluster auth jenkins-master-1 jenkins-master-2 \
    -u "${COROSYNC_USER_NAME}" \
    -p "${COROSYNC_USER_PASSWORD}"

# create initial cluster
pcs cluster setup \
    --name "jenkins-cluster" \
    jenkins-master-1 jenkins-master-2

pcs cluster start --all
# ensure reboot survival
pcs cluster enable --all

# NOTE: STONITH / fencing not implemented yet
pcs property set stonith-enabled=false

# NOTE: disable quorum, this is not needed to fail-over in cold standby mode
pcs property set no-quorum-policy=ignore

# create GlusterFS storage resource
# NOTE: negative-timeout fixes an issue causing a performance hit of GlusterFS client in certain
# cases (e.g. Jenkins: requests available plugin list). It seems (guess), that Jenkins is too fast
# for GlusterFS when writing files (meaning, create+delete is faster then GlusterFS can process them)
JENKINS_DIR_RESOURCE_NAME="jenkins-master-home-dir--rsc"
pcs resource create "${JENKINS_DIR_RESOURCE_NAME}" ocf:heartbeat:Filesystem \
    device="gluster-node-0:/${GLUSTER_BRICK_ID}" \
    directory="${JENKINS_HOME_PATH}" \
    fstype="glusterfs" \
    options=direct-io-mode=disable,negative-timeout=2 \
    fast_stop="no" force_unmount="safe" \
    op stop on-fail=stop timeout=200 \
    op monitor on-fail=stop timeout=200 \
    OCF_CHECK_LEVEL=10

# create Jenkins service resource
JENKINS_SERVICE_RESOURCE_NAME="jenkins-master--rsc"
pcs resource create "${JENKINS_SERVICE_RESOURCE_NAME}" systemd:jenkins \
    op monitor interval="60s" \
    op start interval="45s"

# Stickyness control how likely a resource is moved, like the cost of the move
pcs resource defaults resource-stickiness=100

# bind both resources to one another, to make them run on the same host
pcs constraint colocation add "${JENKINS_SERVICE_RESOURCE_NAME}" with "${JENKINS_DIR_RESOURCE_NAME}" INFINITY

# define order of resources to get started
pcs constraint order "${JENKINS_DIR_RESOURCE_NAME}" then "${JENKINS_SERVICE_RESOURCE_NAME}"

# prefer host one over the other
pcs constraint location "${JENKINS_SERVICE_RESOURCE_NAME}" prefers jenkins-master-1=50
