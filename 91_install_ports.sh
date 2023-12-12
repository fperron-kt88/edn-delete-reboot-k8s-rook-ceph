#!/bin/bash

function port_forward() {
    local nick=$1
    local namespace=$2
    local service=$3
    local local_port=$4
    local dist_port=$5

	# Check if the local port is already in use
	if lsof -Pi :$local_port -sTCP:LISTEN -t &> /dev/null; then
	    : # Placeholder comment to maintain the line without output
#        echo "Port $local_port is already in use. Skipping port-forward for $namespace/$service."
	else
	    # Check if the service exists before attempting to port forward
	    if microk8s kubectl get svc "$service" -n "$namespace" &> /dev/null; then
	        # Run kubectl port-forward in the background
	        microk8s kubectl port-forward -n "$namespace" svc/"$service" "$local_port":"$dist_port" &
	        echo "Port-forwarding $nick\t$namespace/$service from localhost:$local_port to $dist_port"
	    else
	        echo "Service $namespace/$service does not exist. Skipping port-forward installation."
	    fi
	fi
}

# Example usage
while true; do
    port_forward "jupyterhub" "test-fx-ns1-jupyterhub-3-0-1" "proxy-public" 9991 80
    port_forward "mistral_chatbot" "dev-interne-genai-edn-generation-webui-ns" "text-generation-webui-service" 9992 80
    port_forward "fooocus" "dev-interne-genai-edn-fooocus-ns" "dev-interne-genai-edn-fooocus-app-fooocus-app" 9993 6667
    port_forward "powermon" "dev-interne-testmonitoring-edn-powermon-ns" "dev-interne-testmonitoring-edn-powermon-app-powermon-app" 9994 6666
    port_forward "infisical" "infisical-ns" "infisical-app-backend" 9995 8080
    port_forward "obs_grafana" "observability" "kube-prom-stack-grafana" 9996 80
    port_forward "argocd_ui" "argocd" "argocd-server" 9997 443
    port_forward "k8s_dashbd" "kube-system" "kubernetes-dashboard" 9998 443

    sleep 10
done

# Wait for all background jobs to finish
wait




echo "HINT:            ps -ef | grep port-forward | grep 9998 | awk '{print \$2}' | xargs kill -9" 
