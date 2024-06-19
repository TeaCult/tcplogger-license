/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
pacman -Sy --noconfirm stress lm_sensors dmidecode wget
sensors-detect --auto
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/stress.py
python stress.py 120
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp10s0/address)\": \"TestCompleted\"}" http://192.168.5.26:5000/data
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp10s0/address)\": \"$(sensors | tr -d '\n')\"}" http://192.168.5.26:5000/data
badblocks -sv 


