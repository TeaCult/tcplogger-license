/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
pacman -Sy --noconfirm stress lm_sensors dmidecode wget nbd qemu-img
modprobe nbd
nbd-client 192.168.5.26 10809 /dev/nbd0 -N myimage
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)\": \"Installing tcplogger image\"}" http://192.168.5.26:5000/data
qemu-img convert -p -f qcow2 -O raw /dev/nbd0 /dev/sda
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)\": \"Installation of tcplogger image is finished\"}" http://192.168.5.26:5000/data
