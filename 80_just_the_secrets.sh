#!/bin/bash
echo '>>> enabling k8s dashboard'
sudo microk8s kubectl describe secret -n kube-system microk8s-dashboard-token | perl -pe 's/(^token:\s+)(.*)/$1\t-------(k8s dash)--->>>>>>> $2 <<<<<<<---------------/'

echo '>>> WARNING: do not forget to port forward'
echo '# le port forward se fait automagiquement dans le repo jupyter hub... SINON, on peut faire directement:'
echo '#k port-forward -n kube-system svc/kubernetes-dashboard 9997:443'


echo ">>> INFO: this could be handy..."
echo "# argocd admin initial-password -n argocd --insecure"
argocd admin initial-password -n argocd --insecure | perl -pe 's/^(?!\s)(.*)/-------(argocd dash)--->>>>>>> $1 <<<<<<<---------------/'

./60_enable_ceph_dashbord.sh --roll-password --force






### TODO: ce script pourrait en fait tout regénérer les secrets... ou les prendre d'un gestionnaire de secrets...
