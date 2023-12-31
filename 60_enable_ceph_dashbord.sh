#!/bin/bash

force=false
roll_password=false

# Function to generate and roll the password
roll_password_function() {




# TODO: cette partie est blocante...



    echo ">>> sudo microceph.ceph dashboard ac-user-delete admin"
    sudo microceph.ceph dashboard ac-user-delete admin

    echo ">>> Generate a random password"
    random_password=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1)

    echo ">>> Create a password file"
    sudo sh -c "echo -n '$random_password' > /var/snap/microceph/current/conf/password.txt"
    sudo chmod 600 /var/snap/microceph/current/conf/password.txt

    echo ">>> Create the dashboard user"
    sudo microceph.ceph dashboard ac-user-create -i /var/snap/microceph/current/conf/password.txt admin administrator

	# Check the exit code of the last command
    if [ $? -eq 0 ]; then
    	echo ">>> Remove the password file"
    	sudo rm /var/snap/microceph/current/conf/password.txt

    	echo "Ceph admin password setup completed. Random password: ----------(ceph dash)------>>>>>>>> $random_password <<<<<<<<<<<-------------"
        return 0  # Success
    else
    	echo ">>> Remove the password file"
    	sudo rm /var/snap/microceph/current/conf/password.txt

        echo "Error: User creation failed to execute. No password set..."
        exit 1
    fi

}

# Check for options
while [ "$#" -gt 0 ]; do
    case "$1" in
        --force )
            force=true
            shift
            ;;
        --roll-password )
            roll_password=true
            shift
            ;;
        * )
            break
            ;;
    esac
done

if [ "$force" = false ]; then
    read -p "Are you certain? Type 'yes-i-am-certain': " response

    if [ "$response" != "yes-i-am-certain" ]; then
        echo "Skipping execution. Make sure to type 'yes-i-am-certain' to proceed or use --force"
        exit 1
    fi
fi

if [ "$roll_password" = true ]; then
    roll_password_function
else
    echo "Force option detected. Proceeding..."
    echo ">>> microceph: dashboard install"
    sudo microceph.ceph mgr module ls

    echo "TODO enable ssl>>> microceph:  microceph.ceph config set mgr mgr/dashboard/ssl false"
    sudo microceph.ceph config set mgr mgr/dashboard/ssl false

    echo ">>> Enable the dashboard module"
    sudo microceph.ceph mgr module enable dashboard

    #--- begin fucntion to extract
    roll_password_function
    #--- end fucntion to extract

    echo "Ceph idashboard setup completed."

    echo "### pour faire des modifications..."
    echo "#sudo microceph.ceph dashboard ac-user-show admin"
    echo "#sudo microceph.ceph dashboard ac-user-delete admin"
    echo "#sudo microceph.ceph dashboard ac-user-create -i /etc/ceph/password.txt admin administrator"
fi

