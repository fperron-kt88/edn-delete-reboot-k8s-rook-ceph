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
    echo "SuperForce option detected. Proceeding with execution..."
else
    read -p "Are you super certain? Type 'yes-i-am-super-certain': " response
fi

if [ "$response" = "yes-i-am-super-certain" ] || [ "$super_force" = true ]; then

    echo "+++ 10_destroy"
    ./10_destroy-and-automate-microk8s-bootstrap.sh --force
    echo "+++ 20_clean_hdd"
    ./20_clean_hdd_data_wipe_all.sh --force
    echo "+++ 30_provision microceph and microk8s"
    ./30_provision_microceph_and_link_to_microk8s.sh --force
    echo "+++ 40_provision pod"
    ./40_provision_gros_pod_gourmand.sh --force

else
    echo "Skipping execution. Make sure to type 'yes-i-am-super-certain' to proceed or use --super-force"
    exit 1
fi