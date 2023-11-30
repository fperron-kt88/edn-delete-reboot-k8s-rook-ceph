#!/bin/bash

countdown() {
    local seconds=$1
	local task=$2
	local pattern=$3
	local msg=$4

    eval "$task" | grep 'NAME' | perl -pe 's/^/...\t(--)\t/'
    for ((i = seconds; i >= 0; i--)); do
        echo -ne "...\t($i)\t"
 #       eval "$task" | grep -v "NAME"


      	task_output=$($task | grep -v 'NAME') 
        echo "$task_output"

        if [[ $task_output == *"${pattern}"* ]]; then
            echo ${msg}
            break
        fi

        sleep 1
    done

}

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
    echo "Force option detected. Proceeding with execution..."
else
    read -p "Are you certain? Type 'yes-i-am-certain': " response

    if [ "$response" != "yes-i-am-certain" ]; then
        echo "Skipping execution. Make sure to type 'yes-i-am-certain' to proceed."
        exit 1
    else
		echo ">>> k apply -f gros-pod.yaml"
		sudo microk8s kubectl apply -f gros-pod.yaml
		

		echo "... spawning in the pod..."
		echo "... consider typing:"
		echo "# cd /data"
		echo "# dd if=/dev/urandom of=/data/random_data_file bs=1M count=5120"


        echo ">>> k get po -n default"
        countdown 10 'sudo microk8s kubectl get po mypod -n default' 'Running' '>>> Pod is ready. Breaking out of the loop.'
		echo ">>> Contact: k exec -it -n default mypod -- sh"
		sudo microk8s kubectl exec -it -n default mypod -- sh
    fi
fi





