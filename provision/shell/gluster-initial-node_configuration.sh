#!/usr/bin/env bash


DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${DIR}


source ./conf.env


ADDITIONAL_GLUSTER_NODES_INDEX_FILE_PATH="${1}"


# src: https://wiki.centos.org/HowTos/GlusterFSonCentOS



gluster volume create "${GLUSTER_BRICK_ID}" \
        transport tcp \
        "$(hostname):${GLUSTER_JENKINS_BRICK_DIR}" force
gluster volume set "${GLUSTER_BRICK_ID}" storage.owner-gid "${JENKINS_USER_ID}"
gluster volume set "${GLUSTER_BRICK_ID}" storage.owner-uid "${JENKINS_USER_ID}"


nodeCount=1
while read -r additionalGlusterNodeIP
do
    if [ -z "${additionalGlusterNodeIP}" ]; then
        continue;
    fi

    gluster peer probe "${additionalGlusterNodeIP}"

    sleep 10    # because previous command is async in conjunction to the following one

    nodeCount=$(( $nodeCount + 1 ))

    gluster volume add-brick \
        "${GLUSTER_BRICK_ID}" \
        replica "${nodeCount}" \
        "${additionalGlusterNodeIP}:${GLUSTER_JENKINS_BRICK_DIR}" \
        force

    echo "Added gluster node: ${additionalGlusterNodeIP}"

    sleep 4
done < "${ADDITIONAL_GLUSTER_NODES_INDEX_FILE_PATH}"

rm -rf "${ADDITIONAL_GLUSTER_NODES_INDEX_FILE_PATH}"

gluster volume start "${GLUSTER_BRICK_ID}"

gluster volume info
