Jenkins High Availability Example Implementation
================================================


This repository holds an example implementation of an Jenkins HA infrastructure setup solely based 
on Open Source components, whose reason of existence and development process is described 
[in a blog post](TODO).



__Prerequisites:__

+   Ruby
+   Vagrant
+   VirtualBox


### Worth noticing

1.  This setup may also serve as a simple Jenkins playground on your local machine (provides Linux 
    and Windows agents)!
2.  It neither implements nor configurates any security measures other then
    +   private network for all component located behind the load balancer
    +   enabled firewall and some simple rules
3.  STONITH is not (yet) implemented
4.  cluster only implements [cold-standby](https://www.ibm.com/developerworks/community/blogs/RohitShetty/entry/high_availability_cold_warm_hot) mode
5.  components: HAProxy, GlusterFS, Jenkins, Jenkins Swarm Plugin, Pacemaker, Corosync


### Usage

#### Installation

1.  adjust `/conf.env` according to your needs (and available host resources)
2.  `vagrant up`
3.  go to `http[s]:${EXTERNAL_LOAD_BALANCER_IP}:${EXTERNAL_LOAD_BALANCER_PORT}` to visit 
    Jenkins UI


#### Verify cluster state

*NOTE: must be executed as privileged user*

```bash
$  pcs status
$  pcs cluster status
$  pcs status corosync
```

#### Playing with the cluster

To move resources form one node to another (simulate failure), you could stop one node by going into 
the node and do `pcs cluster stop $NODE_NAME` (node name defaults to `local`), or maybe change the 
configuration for the preferred resource location (e.g. `pcs constraint location jenkins-master--rsc prefers jenkins-master-2=INFINITY`).
Another way would be to just send the active node into standby (`pcs cluster standby jenkins-master-1`)


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


#### Configuration Management

The entire provisioning and system setup is implemented with scripts (bash, batch). Today of course,
this is done in a more declarative way, that would also ensure idempotency. Since this examples is 
based on centos7 it would only make sense to use *Ansible* here. But, any technology
[supported by vagrant](https://www.vagrantup.com/docs/provisioning/) would suffice.


### Resources

+   [Blog post on this topic including a more detailed explanation](https://endocode.com/blog/2018/08/17/jenkins-high-availability-setup/)
+   [A cluster from scratch powered by pacemaker](http://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/index.html)
+   [CRM Fencing](https://clusterlabs.org/pacemaker/doc/crm_fencing.html)