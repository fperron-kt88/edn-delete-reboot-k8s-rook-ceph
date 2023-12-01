#!/bin/bash

countdown() {
    local seconds=$1
    local task=$2
    local pattern=$3
    local msg=$4
    local header_pattern=$5


    # Execute the task and display header if provided
    if [ -n "$header_pattern" ]; then
        eval "$task" | grep "${header_pattern}" | perl -pe 's/^/...\t(--)\t/'
    fi

    for ((i = seconds; i >= 0; i--)); do
        echo -ne "...\t($i)\t"

        # Execute the task, exclude lines matching header pattern, and display output
        task_output=$(eval "${task}" | perl -pe "s/${header_pattern}.*\n//")
        echo $task_output

        if [[ $task_output == *"${pattern}"* ]]; then
            echo "${msg}"
            break
        fi

        sleep 1
    done
}

echo ">>> k apply -f gros-pod.yaml"
sudo microk8s kubectl apply -f gros-pod.yaml


echo "... spawning in the pod..."
echo "... consider typing:"
echo "# cd /data"
echo "# dd if=/dev/urandom of=/data/random_data_file bs=1M count=5120"

    echo ">>> k get po -n default"
    countdown 300 'sudo microk8s kubectl get po mypod -n default' 'Running' '>>> Pod is ready. Breaking out of the loop.' NAME

echo ">>> Contact: k exec -it -n default mypod -- sh"
sudo microk8s kubectl exec -it -n default mypod -- sh
