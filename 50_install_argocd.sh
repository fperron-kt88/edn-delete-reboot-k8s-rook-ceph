#!/bin/bash


sudo microk8s kubectl create namespace argocd

echo '>>> TODO: FX fix this!!! WARNING: no revision selected FLOATING REVISION <<<'
sudo microk8s kubectl  apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo apt-get install build-essential

export HOMEBREW_NO_INSTALL_CLEANUP=1
export NONINTERACTIVE=1
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo '>>> TODO: FX fix this!!! WARNING: env KUBECONIFG should probably installed with ansible in the .bashrc'
echo ">>> Add this: eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc
brew install argocd

echo '>>> TODO: FX fix this!!! WARNING: env KUBECONIFG should probably installed with ansible in the .bashrc'
# vi ~/.bashrc
# >export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config
# source ~/.bashrc
### and made more secure
# sudo chmod 600 /var/snap/microk8s/current/credentials/client.config

# noter le password password du argocd-server
admin_initial=$(argocd admin initial-password -n argocd --insecure)
echo $admin_initial | perl -pe 's/^.*?\s+/**** (hidden) ***** /g'
argocd_admin_pw=$(echo $admin_initial | awk '{print $1}')

# noter le cluster ip du argocd-server
cluster_ip=$(sudo microk8s kubectl get svc -n argocd | perl -ne 'next unless /argocd-server\s/;s/.*argocd-server\s.*?ClusterIP\s+(\d+\.\d+\.\d+\.\d+)\s.*/$1/gm;print')

# faire le login du cli
argocd login ${cluster_ip} --username admin --password ${argocd_admin_pw} --insecure

echo '>>> enabling webssh for pods in gui'
sudo microk8s kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data": {"exec.enabled": "true"}}'
sudo microk8s kubectl patch role argocd-server -n argocd --type=merge -p '{"rules": [{"apiGroups": [""], "resources": ["pods"], "verbs": ["exec"]}]}' 

echo '>>> enabling k8s dashboard'
sudo microk8s enable dashboard
sudo microk8s kubectl describe secret -n kube-system microk8s-dashboard-token

echo '>>> WARNING: do not forget to port forward'
echo '# le port forward se fait automagiquement dans le repo jupyter hub... SINON, on peut faire directement:'
echo '#k port-forward -n kube-system svc/kubernetes-dashboard 9997:443'





