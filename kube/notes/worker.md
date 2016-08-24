
### kubelet
To make master a worker, need to add "--api-servers=127.0.0.1:8080" option to kubelet.

On AWS debian default setup, this needs to be added to /etc/sysconfig/kubelet.

### Manually set up kubelet on a bare node:
* Download kubernetes/server/bin binaries (contained in kubernetes.tar.gz)
* Create /var/lib/kubelet/kubeconfig - this needs to be modeled against an existing minion node created by kube-up
* Create /var/lib/kube-proxy/kubeconfig
* Create /etc/kubernetes similar to exising minion node
* Run kubectl create -f addnode.yaml: 

{
  "kind": "Node",
  "apiVersion": "v1",
  "metadata": {
    "name": "10.240.79.157",
    "labels": {
      "name": "my-first-k8s-node"
    }
  }
}

Then run kubelet on the worker node, note the name and above name should match:


