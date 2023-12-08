#!/bin/bash

super_force=false

# Check for --super-force option
while [ "$#" -gt 0 ]; do
    case "$1" in
        --super-force )
            super_force=true
            shift
            ;;
        * )
            break
            ;;
    esac
done

if [ "$super_force" = true ]; then
    echo "SuperForce option detected. Proceeding..."
else
    read -p "Are you super certain? Type 'yes-i-am-super-certain': " response
fi

if [ "$response" = "yes-i-am-super-certain" ] || [ "$super_force" = true ]; then
    # Define a here document to store the list of commands
    commands_list=$(cat <<EOF
./10_destroy_wipe_microk8s_microceph.sh --force
./20_microk8s_bootstrap.sh --force
./30_microceph_bootstrap_provision_and_link_to_microk8s.sh --force
./40_provision_gros_pod_gourmand.sh --script-mode
./50_install_argocd.sh
./60_enable_ceph_dashbord.sh --force
./70_enable_observability.sh --force
EOF
)

    # Iterate through the commands
    IFS=$'\n' # Set Internal Field Separator to newline
    for command in $commands_list; do
        echo "+++ Script: $command" # Print echo statement with prefix
        eval "$command"             # Execute the command
    done
else
    echo "Skipping execution. Make sure to type 'yes-i-am-super-certain' to proceed or use --super-force"
    exit 1
fi
