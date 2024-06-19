/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
pacman -Sy --noconfirm stress lm_sensors dmidecode wget
sensors-detect --auto
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/stress.py
python stress.py 240
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)\": \"TestCompleted\"}" http://192.168.5.26:5000/data

curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-sensors\": \"$(sensors | tr -d '\n')\"}" http://192.168.5.26:5000/data
# badblocks -nsv /dev/sda > badblocks.out
# curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-badblocks\": \"$(cat badblocks.out | tr -d '\n')\"}" http://192.168.5.26:5000/data

sudo smartctl -t short /dev/sda
sleep 120
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"$(smartctl -a /dev/sda | tr -d '\n')\"}" http://192.168.5.26:5000/data



