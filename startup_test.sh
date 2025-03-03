# Define variables
ethname=$(ip link show | awk '/state UP/ {print $2; exit}' | sed 's/://')
macadress=$(ip link show | awk '/state UP/ {getline; print $2; exit}')
nbd_server="192.168.5.26"
nbd_base_port=10809
nbd_device="/dev/nbd0"
max_port_attempts=20
timeout_duration=30  # Timeout for each NBD connection attempt in seconds
base_url="http://192.168.5.26:5000/data"

disk_device="/dev/sda"
# Detect if sda is absent and replace with vda
if [ ! -e /dev/sda ] && [ -e /dev/vda ]; then
    disk_device="/dev/vda"
fi

get_disk_size_gb() {   lsblk -dn -o SIZE -b $1 | awk '{print int($1/1024/1024/1024)}'; }

execute_with_delay() {
  local delay=2
  "$@" || exit 1
  sleep $delay
}

post_data() {
  curl -X POST -H "Content-Type: application/json" -d "{\"$macadress\": \"$1\"}" $base_url
  echo $1
  sleep 2
}


/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux

post_data "Installing test packages and cleaning package manager cache"
pacman -Sy --noconfirm stress lm_sensors dmidecode wget net-tools
pacman -Scc --noconfirm
sensors-detect --auto

post_data "Finished installing test packages and Downloading test Scripts"

wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/stress.py

post_data "Finished downloading scripts"

#post_data "Starting cpu stress test"
#python stress.py 300

#post_data "Finished cpu test and Starting SMART test"

#smartctl -t long $disk_device

#echo "Sleping for 300 seconds to check smart test progress"
#sleep 300

#while grep -q "in progress" <(smartctl -a $disk_device); do
#    sleep 10  # Sleeps for 10 seconds before checking again
#done

#if [[ $(smartctl -a $disk_device) == *"PASSED"* ]]; then
#    post_data "Smart test result is: PASSED"
#    RESULT="PASSED"
#else 
#    post_data "Smart test result is: FAILED"
#    RESULT="FAILED"
#fi

#post_data "All tests are finished. Result is $RESULT. Exiting from script without installation"


############# BADBLOCKS TEST OF FIRST 20 GB ####################
# badblocks -wvs /dev/sda -b 1024 -c 65536 -p 5 20971520

RESULT="TESTBYPASSED"
# Correcting conditional check for exit - Keep installing if it is a virtual machine (no cpu temp - no smart test) 
if [ "$RESULT" == "FAILED" ] && [ "$disk_device" != "/dev/vda" ]; then
    exit 1
fi

############ INSTALL PART (remoteinstall.sh) ##############


# Start installations and configurations
post_data "Performing qemu-img installation"
execute_with_delay pacman -Sy --noconfirm qemu-img
execute_with_delay pacman -Scc --noconfirm


post_data "Loading nbd driver and connecting nbdkit server"
execute_with_delay modprobe nbd
execute_with_delay nbd-client $nbd_server 10809 $nbd_device -N myimage

post_data "Installing tcplogger image"
execute_with_delay qemu-img convert -p -f qcow2 -O raw $nbd_device $disk_device



# Disk operations
post_data "Increasing partition 3 size"
execute_with_delay parted $disk_device resizepart 3 $(get_disk_size_gb $disk_device)G
post_data "Checking part 3 with e2fsck" 
execute_with_delay e2fsck -f -p ${disk_device}3
post_data "Resizing file system on partition 3"
execute_with_delay resize2fs ${disk_device}3 
post_data "Disk resizing operations are finished"

# Disconnect from NBD server
post_data "Disconnecting from NBD server"
execute_with_delay nbd-client -d $nbd_device

post_data "Installation of tcplogger is finished"




