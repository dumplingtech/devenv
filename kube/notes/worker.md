
### kubelet
To make master a worker, need to add "--api-servers=127.0.0.1:8080" option to kubelet.

On AWS debian default setup, this needs to be added to /etc/sysconfig/kubelet.
