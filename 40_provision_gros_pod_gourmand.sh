#!/bin/bash

script_mode=false
max_wait=300

# Check for --script-mode option
while [ "$#" -gt 0 ]; do
    case "$1" in
        --script-mode )
            script_mode=true
            shift
            ;;
        * )
            break
            ;;
    esac
done


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

if [ "$script_mode" = true ]; then
    echo "script mode detected. Proceeding fast and non interactive..."
    countdown ${max_wait} 'sudo microk8s kubectl get po mypod-cephtest -n default' 'Running' '>>> Pod is ready. Breaking out of the loop.' NAME
    sudo microk8s kubectl exec -it -n default mypod-cephtest -- sh -c 'hostname;ps -ef;ls -l;ls -l /data;dd if=/dev/urandom of=/data/random_data_file bs=1M count=50;ls -lh /data; rm /data/random_data_file; ls -lh /data'

else
    echo "... spawning in the pod..."
    echo "... for 5Gi data test, consider typing:"
    echo "# cd /data"
    echo "# dd if=/dev/urandom of=/data/random_data_file bs=1M count=5120"

    echo ">>> k get po -n default"
    countdown ${max_wait} 'sudo microk8s kubectl get po mypod-cephtest -n default' 'Running' '>>> Pod is ready. Breaking out of the loop.' NAME
    echo ">>> Contact: k exec -it -n default mypod-cephtest -- sh"
    
    sudo microk8s kubectl exec -it -n default mypod-cephtest -- sh
fi

