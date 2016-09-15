# k8s node setup
We setup nodes so that they can readily run k8s. After one type of node is setup, we can create AMIs from snapshots so that later deployments will be faster.

Before running steps, the following needs to be configured
* inventory/inventory
* inventory/group_vars
* (optional) configure and run cert/run.sh to generate the self-signed certificates. Do this only if you don't have proper certificates.
* copy the certificates to roles/kubelet/templates/certs
* run deploy-all.sh

