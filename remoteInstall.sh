#!/bin/bash

exec > >(tee -a /mypxebootlog) 2>&1
set -x

# Define variables
nbd_server="192.168.5.26"
nbd_base_port=10809
nbd_device="/dev/nbd0"
disk_device="/dev/sda"
max_port_attempts=20
timeout_duration=5  # Timeout for each NBD connection attempt in seconds

# Detect if sda is absent and replace with vda
if [ ! -e /dev/sda ] && [ -e /dev/vda ]; then
    disk_device="/dev/vda"
fi

# Initialize pacman keys and install required packages
mkdir -p /etc/pacman.d/gnupg
chmod 700 /etc/pacman.d/gnupg
/usr/bin/pacman-key --init || exit 1
sleep 2
echo "adjusting pacman keys"
/usr/bin/pacman-key --populate archlinux || exit 1
sleep 2
pacman -Sy --noconfirm stress lm_sensors || exit 1
sleep 2
echo "Cleaning cache"
pacman -Scc --noconfirm
sleep 2
pacman -Sy --noconfirm dmidecode wget nbd || exit 1
sleep 2
echo "Cleaning cache"
pacman -Scc --noconfirm
sleep 2
pacman -Sy --noconfirm qemu-img || exit 1
sleep 2
echo "Cleaning cache"
pacman -Scc --noconfirm
sleep 2
echo "loading nbd drivers"
modprobe nbd || exit 1
sleep 2

# Try to connect to NBD server with fallback on ports
for ((i=0; i<max_port_attempts; i++)); do
    nbd_port=$((nbd_base_port + i))
    echo "Attempting to connect to NBD server on port $nbd_port"
    if timeout $timeout_duration nbd-client $nbd_server $nbd_port $nbd_device -N myimage; then
        echo "Successfully connected to NBD server on port $nbd_port"
        break
    elif [ $i -eq $((max_port_attempts - 1)) ]; then
        echo "Failed to connect to NBD server after $max_port_attempts attempts"
        exit 1
    else
        echo "Port $nbd_port not available, trying next port..."
    fi
    sleep 2
done

# Report installation status to the server
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)\": \"Installing tcplogger image\"}" http://$nbd_server:5000/data
sleep 2

# Install the image to the disk
echo "Installing tcploggerv2 image to the disk"
qemu-img convert -p -f qcow2 -O raw $nbd_device $disk_device || exit 1
sleep 2

# Report completion status to the server
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)\": \"Installation of tcplogger image is finished\"}" http://$nbd_server:5000/data
sleep 2

# Increase disk size
echo "Increasing Disk Size"
parted $disk_device resizepart 3 320G || exit 1
sleep 2
e2fsck -f -p ${disk_device}3 || exit 1
sleep 2
resize2fs ${disk_device}3 275G || exit 1
sleep 2

# Disconnect from NBD server
echo "Disconnecting from NBD server"
nbd-client -d $nbd_device || exit 1
sleep 2

echo "Installation is Finished you can reboot"
