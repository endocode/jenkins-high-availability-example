#!/usr/bin/env bash



echo "10.11.11.21 gluster-node-0" | sed -e '/'"$(hostname)"'/d' >> /etc/hosts

echo "10.11.11.31 jenkins-master-1" >> /etc/hosts
echo "10.11.11.32 jenkins-master-2" >> /etc/hosts

echo "10.11.11.11 load-balancer" | sed -e '/'"$(hostname)"'/d' >> /etc/hosts
