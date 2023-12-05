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
    echo ">>> Enable the observability dashboard module with prometheus and grafana"
    sudo microk8s enable observability

    echo "TODO: this is bad: The password is alwas this:  user/pass: admin/prom-operator"
else
    echo "Skipping execution. Make sure to type 'yes-i-am-certain' to proceed or use --force"
    exit 1
fi
