#!/bin/bash

force=false

# Set the disk path and intented osd capacity and config
DISK="/hdd"
OSD_SIZE="580G"
OSD_POOL_SIZE=3

# Function to check if disk is mounted
check_mount() {
  if ! mountpoint -q "$DISK"; then
    echo "Error: $DISK is not mounted."
    echo
	echo "# Here are the steps you want to perform to mount the disk:"
	echo "## TODO: automatiser ça..."
	echo "# lsblk | grep sda"
	echo "# sudo mkdir /hdd"
	echo "# lsblk"
	echo "# parted rm et on en garde que /dec/sda de 1.8 TB"
	echo "# sudo mkfs.ext4 /dev/sda"
	echo "# sudo mount /dev/sda /hdd"
    echo
	echo "# don't forget to edit /etc/fstab:"
	echo "#   /dev/sda  /hdd  ext4  defaults  0  2"

    exit 1
  fi
}

# Function to check available space
check_space() {
  available_space=$(df -BG --output=avail "$DISK" | tail -n 1 | sed 's/G//')
  required_space=$((OSD_POOL_SIZE * ${OSD_SIZE%"G"}))
  max_osd_space=$((${available_space} / $OSD_POOL_SIZE))

  if [ "$available_space" -lt "$required_space" ]; then
    echo "Error: Insufficient space on $DISK. Required: $required_space GB, Available: $available_space GB"
    echo "Solution: you want an OSD_SIZE no larger than ${max_osd_space} GB in this script ($0)"
    exit 1
  fi
}




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

        echo ">>> Requirement checks: /hdd is mounted and sufficient?"
		check_mount
		check_space

        echo ">>> microceph: install"
        sudo snap install microceph
        echo ">>> microceph: install hold"
        sudo snap refresh --hold microceph
        echo ">>> microceph: cluster bootstrap"
        sudo microceph cluster bootstrap
        echo ">>> microceph: status"
        sudo microceph status

      	echo ">>> microceph: Check if *.img files exist in /hdd"
		if ls /hdd/*.img 1> /dev/null 2>&1; then
		  read -p "WARNING: *.img files already exist in /hdd. Continuing will overwrite existing files. Do you want to continue? (y/n): " choice
		  if [ "$choice" != "y" ]; then
		    echo "Aborted by user."
		    exit 1
		  fi
		fi
		
		echo "... Check if loop devices are already present"
		if ls /dev/sdi* 1> /dev/null 2>&1; then
		  read -p "WARNING: Loop devices are already in use. Continuing will overwrite existing loops. Do you want to continue? (y/n): " choice
		  if [ "$choice" != "y" ]; then
		    echo "Aborted by user."
		    exit 1
		  fi
		fi
		
		echo "... Create loop devices and *.img files"
		for l in a b c; do
		  loop_file="/hdd/${l}.img"
		
		  echo "... Check if the img file ${loop_file} already exists"
		  if [ -e "$loop_file" ]; then
		    read -p "WARNING: $loop_file already exists. Continuing will overwrite the file. Do you want to continue? (y/n): " choice
		    if [ "$choice" != "y" ]; then
		      echo "Aborted by user."
		      exit 1
		    fi
		  fi
		
		  echo "... Extending file to size"
		  sudo truncate -s ${OSD_SIZE} "${loop_file}"
		  loop_dev="$(sudo losetup --show -f "${loop_file}")"
		  # the block-devices plug doesn't allow accessing /dev/loopX
		  # devices so we make those same devices available under alternate
		  # names (/dev/sdiY)
		  minor="${loop_dev##/dev/loop}"
		  echo "... mknode"
		  sudo mknod -m 0660 "/dev/sdi${l}" b 7 "${minor}"
		  echo ">>> microceph: disk add /dev/sdi${l}"
		  sudo microceph disk add --wipe "/dev/sdi${l}"
		done
		
		echo ">>> microceph: Loop devices and *.img files created successfully."

		echo ">>> microceph: ceph status"
		sudo microceph.ceph status
		echo ">>> microceph: disk list"
		sudo microceph disk list
		echo ">>> microceph: osd tree"
		sudo ceph osd tree
		echo ">>> microceph: osd stat"
		sudo ceph osd stat
		
		echo ">>> microceph: set pool size to ${OSD_POOL_SIZE} (write an objet ${OSD_POOL_SIZE} times)"
		sudo microceph.ceph config set global osd_pool_default_size ${OSD_POOL_SIZE}
        
        # Accept an I/O operation to a PG that has two copies of an object.
        echo ">>> microceph: set default min size size to 2 (to accept I/O ops on a PG with 2 copies)"
        sudo microceph.ceph config set global osd_pool_default_min size 2 

		echo ">>> microceph: status --wait-ready"
		sudo microk8s status --wait-ready
		echo ">>> microk8s: enable rook-ceph"
		sudo microk8s enable rook-ceph
		
		echo ">>> microk8s: k get all --all-namespaces"
		sudo microk8s kubectl get all --all-namespaces
		echo ">>> microk8s: k get no"
		sudo microk8s kubectl get no
		echo ">>> microk8s: connect external ceph"
		sudo microk8s connect-external-ceph
else
    echo "Skipping execution. Make sure to type 'yes-i-am-certain' to proceed or use --force"
    exit 1
fi
