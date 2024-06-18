/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
pacman -Sy --noconfirm stress lm_sensors dmidecode wget nbd qemu-img
modprobe nbd
nbd-client 192.168.5.26 10809 /dev/nbd0 -N myimage
qemu-img convert -p -f qcow2 -O raw /dev/nbd0 /dev/sda
