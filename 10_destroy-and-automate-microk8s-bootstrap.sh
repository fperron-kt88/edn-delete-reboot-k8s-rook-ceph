#!/bin/bash

force=false

# Check for --force option
while [ "$#" -gt 0 ]; do
    case "$1" in
        --force )
            force=true
            shift
            ;;
        * )
            break
            ;;
    esac
done

if [ "$force" = true ]; then
    echo "Force option detected. Proceeding..."
else
    read -p "Are you certain? Type 'yes-i-am-certain': " response
fi

if [ "$response" = "yes-i-am-certain" ] || [ "$force" = true ]; then
        echo ">>> microk8s: reset destroy storage"
		sudo microk8s reset --destroy-storage
        echo ">>> microk8s: remove and purge config"
		sudo snap remove microk8s --purge

        echo ">>> microk8s: install..."
		sudo snap install microk8s --classic --channel=1.28/stable
        echo ">>> microk8s: hold..."
		sudo snap refresh --hold microk8s

        echo ">>> usermod add group"
		sudo usermod -a -G microk8s fperron
        echo ">>> mkdir"
		mkdir -p ~/.kube
        echo ">>> chown"
		sudo chown -R fperron ~/.kube
        echo ">>> newgrp"
		newgrp microk8s


        echo ">>> microk8s: starting..."
		sudo microk8s start
        echo ">>> status"
		sudo microk8s status
		#sudo microk8s inspect # si problème pour avoir un tar.gz

        echo ">>> microk8s: final config, cluster info and contexts..."
		# sur serveur primaire
		sudo microk8s config > ~/.kube/config
        echo ">>> chmod"
		chmod 600 ~/.kube/config

		#sudo microk8s add-node
		#sur secondaire:
		#microk8s join <100.83.4.64:25000/f715c...>

        echo ">>> cluster-info"
		sudo microk8s kubectl cluster-info
		#sudo snap install helm      (il va chialer pour de la sécurité --classic TBC)
		#helm list
        echo ">>> get-context"
		sudo microk8s kubectl config get-contexts
        echo ">>> use-context"
		sudo microk8s kubectl config use-context microk8s
else
    echo "Skipping execution. Make sure to type 'yes-i-am-certain' to proceed or use --force"
    exit 1
fi
