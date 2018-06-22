Jenkins High Availability Example Implementation
================================================


This repository holds an example implementation whose context and development process is described 
[here](TODO) in a blog post.



__Prerequisites:__

+   Ruby
+   Vagrant
+   VirtualBox


### Worth noticing

1.  This setup could also serve as a simple Jenkins playground on your local machine!
2.  It neither implements nor configurates any security mechanisms other then
    +   private network for every component located behind the load balancer
    +   simple firewall rules
3.  STONITH is not (yet) implemented
4.  Cluster only implements [https://www.ibm.com/developerworks/community/blogs/RohitShetty/entry/high_availability_cold_warm_hot](cold-standby) mode


### Usage

#### Installation

1.  adjust `/conf.env` according to your needs (and probably host resources)
2.  `vagrant up`
3.  go to `http[s]:${EXTERNAL_LOAD_BALANCER_IP}:${EXTERNAL_LOAD_BALANCER_PORT}` to visit 
    Jenkins UI


#### Verify cluster state

```bash
pcs status
pcs cluster status
pcs status corosync
```

#### Playing with the cluster

To move resources form one node to another, you could just stop one node by going into the node and 
do `pcs cluster stop` (node name defaults to `local`). Alternatively change the preferred resource 
location (e.g. `pcs constraint location jenkins-master--rsc prefers jenkins-master-2=INFINITY`) or
make a node node going into standby (`pcs cluster standby jenkins-master-1`)


### Future Work

#### Approaches to implement STONITH

1)  the HAProxy instance could play a role in fencing implementation, e.g. by preventing the dead 
    node from getting traffic.
2)  closing down firewall on all gluster nodes to prevent unwanted access by a *dead* jenkins master 
    node
3)  depending on availability, using cloud provider's API to shutdown a jenkins master node in 
    question
4)  ...?

Both approaches require to write a fence agent from scratch, see
+   https://github.com/ClusterLabs/fence-agents
+   https://docs.pagure.org/ClusterLabs.fence-agents/FenceAgentAPI.md
+   `/usr/share/fence/`


### Resources

+   TODO: blog post link
+   http://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/index.html
+   https://clusterlabs.org/pacemaker/doc/crm_fencing.html