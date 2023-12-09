#!/bin/bash

function port_forward() {
    local nick=$1
    local namespace=$2
    local service=$3
    local local_port=$4
    local dist_port=$5

    # Check if the local port is already in use
    if lsof -Pi :$local_port -sTCP:LISTEN -t &> /dev/null; then
        echo "Port $local_port is already in use. Skipping port-forward for $namespace/$service."
    else
        # Run kubectl port-forward in the background
        microk8s kubectl port-forward -n $namespace svc/$service $local_port:$dist_port &
        echo "Port-forwarding $nick\t$namespace/$service from localhost:$local_port to $dist_port"
    fi
}

# Example usage
port_forward "fooocus" "dev-interne-testgenerative-edn-fooocus-ns" "dev-interne-testgenerative-edn-fooocus-app-fooocus-app" 9992 80
port_forward "powermon" "dev-interne-testmonitoring-edn-powermon-ns" "dev-interne-testmonitoring-edn-powermon-app-powermon-app" 9993 6666
port_forward "infisical" "infisical-ns" "infisical-app-backend" 9994 8080
port_forward "obs_grafana" "observability" "kube-prom-stack-grafana" 9995 80
port_forward "jupyterhub" "test-fx-ns1-jupyterhub-3-0-1" "proxy-public" 9996 80
port_forward "k8s_dashbd" "kube-system" "kubernetes-dashboard" 9997 443
port_forward "argocd_ui" "argocd" "argocd-server" 9998 443

# Wait for all background jobs to finish
wait




echo "HINT:            ps -ef | grep port-forward | grep 9998 | awk '{print \$2}' | xargs kill -9" 
