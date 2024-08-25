ethname=$(ip link show | awk '/state UP/ {print $2; exit}' | sed 's/://')
macadress=$(ip link show | awk '/state UP/ {getline; print $2; exit}')

# Detect if sda is absent and replace with vda
if [ ! -e /dev/sda ] && [ -e /dev/vda ]; then
    disk_device="/dev/vda"
fi

/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)\": \"Installing test packages\"}" http://192.168.5.26:5000/data
pacman -Sy --noconfirm stress lm_sensors dmidecode wget net-tools
pacman -Scc --noconfirm
sensors-detect --auto
curl -X POST -H "Content-Type: application/json" -d "{\"macadress\": \"Finished installing test packages\"}" http://192.168.5.26:5000/data
curl -X POST -H "Content-Type: application/json" -d "{\"macadress\": \"Downloading scripts\"}" http://192.168.5.26:5000/data
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/stress.py
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/checkids.py
curl -X POST -H "Content-Type: application/json" -d "{\"macadress\": \"Finished downloading scripts\"}" http://192.168.5.26:5000/data

curl -X POST -H "Content-Type: application/json" -d "{\"macadress\": \"Started Stress test\"}" http://192.168.5.26:5000/data
python stress.py 600
curl -X POST -H "Content-Type: application/json" -d "{\"macadress\": \"Finished cpu test\"}" http://192.168.5.26:5000/data
curl -X POST -H "Content-Type: application/json" -d "{\"macadress\": \"Starting smartcl test\"}" http://192.168.5.26:5000/data
smartctl -t long $disk_device
echo "Waiting for smart test to finish"
while grep -q "in progress" <(smartctl -a $disk_device); do
    sleep 10  # Sleeps for 10 seconds before checking again
done

if [[ $(smartctl -a $disk_device) == *"PASSED"* ]]; then
    curl -X POST -H "Content-Type: application/json" -d "{\"macadress\": \"Smart test result is: PASSED\"}" http://192.168.5.26:5000/data
else 
    curl -X POST -H "Content-Type: application/json" -d "{\"macadress\": \"Smart test result is: FAILED\"}" http://192.168.5.26:5000/data
fi
curl -X POST -H "Content-Type: application/json" -d "{\"macadress\": \"All tests are finished nothing more to perform\"}" http://192.168.5.26:5000/data

############ INSTALL PART (remoteinstall.sh) ##############



# Define variables
nbd_server="192.168.5.26"
nbd_base_port=10809
nbd_device="/dev/nbd0"
disk_device="/dev/sda"
max_port_attempts=20
timeout_duration=30  # Timeout for each NBD connection attempt in seconds

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
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/$ethname/address)\": \"Installing tcplogger image\"}" http://$nbd_server:5000/data
sleep 2

# Install the image to the disk
echo "Installing tcploggerv2 image to the disk"
qemu-img convert -p -f qcow2 -O raw $nbd_device $disk_device || exit 1
sleep 2

# Report completion status to the server
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/$ethname/address)\": \"Installation of tcplogger image is finished\"}" http://$nbd_server:5000/data
sleep 2

# Increase disk size
echo "Increasing Disk Size"
parted $disk_device resizepart 3 320G || exit 1
sleep 2
e2fsck -f -p ${disk_device}3 || exit 1
sleep 2
resize2fs ${disk_device}3 275G || exit 1
sleep 2

curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/$ethname/address)\": \"Resizing of disk is finished\"}" http://$nbd_server:5000/data
sleep 2

# Disconnect from NBD server
echo "Disconnecting from NBD server"
nbd-client -d $nbd_device || exit 1
sleep 2

echo "Installation is Finished you can reboot"

curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/$ethname/address)\": \"Installation of tcplogger is finished\"}" http://$nbd_server:5000/data
sleep 2



