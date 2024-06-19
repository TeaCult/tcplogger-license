/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
pacman -Sy --noconfirm stress lm_sensors dmidecode wget net-tools
pacman -Scc --noconfirm
pacman -Sy --noconfirm python-crypto python-qrcode 
pacman -Scc --noconfirm 
pacman -Sy --noconfirm lshw
sensors-detect --auto
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/stress.py
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/checkids.py
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/qrcode-gen.py

python3 qrcode-gen.py $(cat /sys/class/net/enp0s25/address)

#python stress.py 600
#smartctl -t long /dev/sda
#echo "Sleep command is issued for 150 seconds"
#sleep 4000
#curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"$(smartctl -a /dev/sda | tr -d '\n')\"}" http://192.168.5.26:5000/data



