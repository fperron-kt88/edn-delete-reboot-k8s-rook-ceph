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
    echo "Force option detected. Proceeding with execution..."
else
    read -p "Are you certain? Type 'yes-i-am-certain': " response

    if [ "$response" != "yes-i-am-certain" ]; then
        echo "Skipping execution. Make sure to type 'yes-i-am-certain' to proceed."
        exit 1
    else
        echo ">>> microceph: reset and purge config"
        sudo snap remove microceph --purge
        echo ">>> microceph: removing /hdd data"
        sudo rm -rf /hdd/*.img
        echo ">>> microceph: removing loop devices"
        sudo losetup -l | grep deleted | awk '{print $1}' | sudo xargs -n 1 losetup -d

        # ici, il faut valider si ce sont les bons!!!
        echo ">>> microceph: removing /dev/sdi*"
        sudo rm -f /dev/sdia
        sudo rm -f /dev/sdib
        sudo rm -f /dev/sdic
    fi
fi

