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

    echo "TODO: this is bad: The password is always this:  grafana user/pass: admin/prom-operator"
	echo
	echo "Ok got two ways:"
	echo
	echo "    you can use the UI ( after login with defaults )"
	echo "    or use grafana-cli in the container microk8s kubectl exec --stdin --tty kube-prom-stack-grafana-*** sh -n observability"
	echo
	echo "Still wondering if there is some way to configure default for this, would be nice for automatic setups."





else
    echo "Skipping execution. Make sure to type 'yes-i-am-certain' to proceed or use --force"
    exit 1
fi
