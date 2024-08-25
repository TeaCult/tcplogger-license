# Define variables
ethname=$(ip link show | awk '/state UP/ {print $2; exit}' | sed 's/://')
macadress=$(ip link show | awk '/state UP/ {getline; print $2; exit}')
nbd_server="192.168.5.26"
nbd_base_port=10809
nbd_device="/dev/nbd0"
max_port_attempts=20
timeout_duration=30  # Timeout for each NBD connection attempt in seconds
base_url="http://192.168.5.26:5000/data"

disk=device="/dev/sda"
# Detect if sda is absent and replace with vda
if [ ! -e /dev/sda ] && [ -e /dev/vda ]; then
    disk_device="/dev/vda"
fi

post_data() {
  curl -X POST -H "Content-Type: application/json" -d "{\"$macadress\": \"$1\"}" $base_url
}


/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux

post_data "Installing test packages and cleaning package manager cache"
pacman -Sy --noconfirm stress lm_sensors dmidecode wget net-tools
pacman -Scc --noconfirm
sensors-detect --auto

post_data "Finished installing test packages and Downloading test Scripts"

wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/stress.py
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/checkids.py

post_data "Finished downloading scripts"

post_data "Starting cpu stress test"
python stress.py 600

post_data "Finished cpu test and Starting SMART test"
smartctl -t long $disk_device
echo "Waiting for smart test to finish"
while grep -q "in progress" <(smartctl -a $disk_device); do
    sleep 10  # Sleeps for 10 seconds before checking again
done

if [[ $(smartctl -a $disk_device) == *"PASSED"* ]]; then
    post_data "Smart test result is: PASSED"
    RESULT="PASSED"
else 
    post_data "Smart test result is: FAILED"
    RESULT="FAILED"
fi

post_data "All tests are finished. Result is $RESULT. Exiting from script without installation"

# Correcting conditional check for exit
if [ "$RESULT" == "FAILED" ]; then
    exit 1 
fi

############ INSTALL PART (remoteinstall.sh) ##############


sleep 2
pacman -Sy --noconfirm qemu-img || exit 1
sleep 2
echo "Cleaning cache"
pacman -Scc --noconfirm
sleep 2
echo "loading nbd drivers"
modprobe nbd || exit 1
sleep 2
nbd-client 192.168.5.26 10809 /dev/nbd0 -N myimage || exit 1
sleep 2 
# Report installation status to the server
post_data "Installing tcplogger image\"}" http://$nbd_server:5000/data
sleep 2

# Install the image to the disk
echo "Installing tcploggerv2 image to the disk"
qemu-img convert -p -f qcow2 -O raw $nbd_device $disk_device || exit 1
sleep 2

# Report completion status to the server
post_data "Installation of tcplogger image is finished\"}" http://$nbd_server:5000/data
sleep 2

# Increase disk size
echo "Increasing Disk Size"
parted $disk_device resizepart 3 320G || exit 1
sleep 2
e2fsck -f -p ${disk_device}3 || exit 1
sleep 2
resize2fs ${disk_device}3 275G || exit 1
sleep 2

post_data "Resizing of disk is finished\"}" http://$nbd_server:5000/data
sleep 2

# Disconnect from NBD server
echo "Disconnecting from NBD server"
nbd-client -d $nbd_device || exit 1
sleep 2

echo "Installation is Finished you can reboot"

post_data "Installation of tcplogger is finished\"}" http://$nbd_server:5000/data
sleep 2



