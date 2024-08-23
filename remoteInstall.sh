exec > >(tee -a /mypxebootlog) 2>&1
set -x
mkdir -p /etc/pacman.d/gnupg
chmod 700 /etc/pacman.d/gnupg
/usr/bin/pacman-key --init ||exit 1
sleep 2
echo "adjusting pacman keys"
/usr/bin/pacman-key --populate archlinux ||exit 1
sleep 2
pacman -Sy --noconfirm stress lm_sensors dmidecode wget nbd qemu-img ||exit 1
sleep 2
echo "loading nbd drivers"
modprobe nbd ||exit 1 
sleep 2
echo "connecting to nbd-server via nbd-client"
nbd-client 192.168.5.26 10809 /dev/nbd0 -N myimage || exit 1
sleep 2
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)\": \"Installing tcplogger image\"}" http://192.168.5.26:5000/data
sleep 2
echo "Installing tcploggerv2 image to the disk"
qemu-img convert -p -f qcow2 -O raw /dev/nbd0 /dev/sda || exit 1
sleep 2
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)\": \"Installation of tcplogger image is finished\"}" http://192.168.5.26:5000/data
echo "Increasing Disk Size"
sleep 2
parted /dev/sda resizepart 3 320G || exit 1
sleep 2
e2fsck -f -p /dev/sda3 || exit 1
sleep 2
resize2fs /dev/sda3 275G || exit 1
sleep 2
echo "Disconnecting from nbd server"
nbd-client -d /dev/nbd0 || exit 1
sleep 2
echo "Installation is Finished you can reboot"
