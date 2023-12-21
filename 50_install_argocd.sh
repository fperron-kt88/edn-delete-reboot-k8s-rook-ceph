#!/bin/bash

### Ce script laisse probablement argocd mal logu/ sur le CLI... il faut faire le login manuellement...

tag="v2.9.3"  # Replace with the specific tag you want
echo ">>> Checking if tag ${tag} exixsts for argocd"
release_info=$(curl -s "https://api.github.com/repos/argoproj/argo-cd/releases/tags/$tag")
latest_tag=$(echo "$release_info" | grep '"tag_name":' | cut -d'"' -f4)

if [ "$latest_tag" == "$tag" ]; then
    echo "Release information for tag $tag:"
#    echo "$release_info" This is a mess __TODO__ Fix this by using gh + auth or some other means...
else
    echo "!!!!!!!! Error: The specified tag $tag does not exist."
	exit 1
fi

echo ">>> Checking for a newer tag than ${tag}"
fixed_tag=$tag
latest_tag=$(curl -s "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name":' | cut -d'"' -f4)

if [ "$fixed_tag" != "$latest_tag" ]; then
        echo ">>> WARNING: A newer tag ($latest_tag) is available. Consider upgrading."
fi
argo_cd_url="https://raw.githubusercontent.com/argoproj/argo-cd/${fixed_tag}/manifests/install.yaml"

echo ">>> Create namespace"
sudo microk8s kubectl create namespace argocd --dry-run=client -o yaml | sudo microk8s kubectl apply -f -
echo ">>> Install from manifest ${fixed_tag}"
sudo microk8s kubectl  apply -n argocd -f ${argo_cd_url}
echo '>>> Install build-essential <<<'
sudo apt-get install build-essential

export HOMEBREW_NO_INSTALL_CLEANUP=1
export NONINTERACTIVE=1
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo '>>> TODO: FX fix this!!! WARNING: env KUBECONIFG should probably be installed with ansible in the .bashrc'
echo ">>> Add this: eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc
brew install argocd

echo '>>> TODO: FX fix this!!! WARNING: env KUBECONIFG should probably be installed with ansible in the .bashrc'
# vi ~/.bashrc
# >export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config
# source ~/.bashrc
### and made more secure
# sudo chmod 600 /var/snap/microk8s/current/credentials/client.config

# noter le password password du argocd-server
echo '>>> argocd gathering password setup'
admin_initial=$(argocd admin initial-password -n argocd --insecure)
echo $admin_initial | perl -pe 's/^.*?\s+/**** (hidden) ***** /g'
argocd_admin_pw=$(echo $admin_initial | awk '{print $1}')

# noter le cluster ip du argocd-server
echo '>>> argocd gathering server ip'
cluster_ip=$(sudo microk8s kubectl get svc -n argocd | perl -ne 'next unless /argocd-server\s/;s/.*argocd-server\s.*?ClusterIP\s+(\d+\.\d+\.\d+\.\d+)\s.*/$1/gm;print')

# faire le login du cli
echo '>>> argocd login'
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


echo ">>> INFO: this could be handy..."
echo "# argocd admin initial-password -n argocd --insecure"
echo "# ------------ ${cluster_ip} ------------- ${argocd_admin_pw} ------------"

