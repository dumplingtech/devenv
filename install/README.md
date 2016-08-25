# k8s node setup
We setup nodes so that they can readily run k8s. After one type of node is setup, we can create AMIs from snapshots so that later deployments will be faster.

The setup steps are:

* setup docker - remove docker0, change config, set up cbr0, give it address 10.2.0.1, do "ip link set dev cbr0 up", bring up docker to use cbr0. ([reference](http://kubernetes.io/docs/getting-started-guides/scratch/)). 
* setup /lib/systemd/system/docker.service, systemctl daemon-reload, systemctl start docker
* Install kube binaries.
* Run kubelet
* Use kubelet manifest to bring up etcd.
* Bring up flannel using etcd, using kubelet manifest.
* create TLS assets (specific to the services only)
* create kube api server, proxy, scheduler, and control manager through kubelet manifests (master only)

