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
    echo ">>> microceph: dashboard install"
    sudo microceph.ceph mgr module ls

    echo "TODO enable ssl>>> microceph:  microceph.ceph config set mgr mgr/dashboard/ssl false"
    sudo microceph.ceph config set mgr mgr/dashboard/ssl false

    echo ">>> Enable the dashboard module"
    sudo microceph.ceph mgr module enable dashboard

	echo ">>> sudo microceph.ceph dashboard ac-user-delete admin"
	sudo microceph.ceph dashboard ac-user-delete admin

    echo ">>> Generate a random password"
    random_password=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1)

    echo ">>> Create a password file"
    sudo sh -c "echo -n '$random_password' > /var/snap/microceph/current/conf/password.txt"
    sudo chmod 600 /var/snap/microceph/current/conf/password.txt

    echo ">>> Create the dashboard user"
    sudo microceph.ceph dashboard ac-user-create -i /var/snap/microceph/current/conf/password.txt admin administrator

    echo ">>> Remove the password file" 
    sudo rm /var/snap/microceph/current/conf/password.txt

    echo "Ceph dashboard setup completed. Random password: $random_password"

	echo "### pour faire des modifications..."
	echo "#sudo microceph.ceph dashboard ac-user-show admin"
	echo "#sudo microceph.ceph dashboard ac-user-delete admin"
	echo "#sudo microceph.ceph dashboard ac-user-create -i /etc/ceph/password.txt admin administrator"

else
    echo "Skipping execution. Make sure to type 'yes-i-am-certain' to proceed or use --force"
    exit 1
fi
