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

        echo ">>> disconnect microk8s from microceph"
        sudo microk8s disconnect-external-ceph

        timeout=5
		echo ">>> Scale down Ceph OSDs"
		timeout ${timeout} sudo microk8s kubectl scale --replicas=0 -n rook-ceph deploy/rook-ceph-osd
		echo ">>> Monitor OSD pod termination"
		timeout ${timeout} sudo microk8s kubectl get pods -n rook-ceph
		echo ">>> Scale down Rook Ceph Operator"
		timeout ${timeout} sudo microk8s kubectl scale --replicas=0 deploy/rook-ceph-operator -n rook-ceph
		echo ">>> Monitor Operator pod termination"
		timeout ${timeout} sudo microk8s kubectl get pods -n rook-ceph
		echo ">>> Remove Rook Custom Resource Definitions (CRDs)"
		sudo microk8s kubectl get crd -n rook-ceph | grep ceph.rook.io | awk '{print $1}' | timeout ${timeout} xargs -n 1 sudo microk8s kubectl delete crd  --grace-period=0
		echo ">>> Remove Rook Namespace (Optional)"
		timeout ${timeout} sudo microk8s kubectl delete namespace rook-ceph


#        echo ">>> microk8s: reset destroy storage"             # it turns out that the reset keeps stuff... even with purge in any case: it is way too long...
#		sudo microk8s reset --destroy-storage
        echo ">>> snap for microk8s: remove and purge config"
		sudo snap remove microk8s --purge

        echo ">>> snap for microceph: reset and purge config"
        sudo snap remove microceph --purge
        echo ">>> rm: removing /hdd data"
        sudo rm -rf /hdd/*.img
        echo ">>> losetup: removing loop devices"
        sudo losetup -l | grep deleted | awk '{print $1}' | sudo xargs -n 1 losetup -d

        # ici, il faut valider si ce sont les bons!!!
        echo ">>> rm: removing /dev/sdi*"
        sudo rm -f /dev/sdia
        sudo rm -f /dev/sdib
        sudo rm -f /dev/sdic
else
    echo "Skipping execution. Make sure to type 'yes-i-am-certain' to proceed or use --force"
    exit 1
fi
