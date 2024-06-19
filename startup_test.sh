/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"Installing test packages\"}" http://192.168.5.26:5000/data
pacman -Sy --noconfirm stress lm_sensors dmidecode wget net-tools
pacman -Scc --noconfirm
pacman -Sy --noconfirm python-crypto python-qrcode 
pacman -Scc --noconfirm 
pacman -Sy --noconfirm lshw
sensors-detect --auto
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"Finished installing test packages\"}" http://192.168.5.26:5000/data
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"Downloading scripts\"}" http://192.168.5.26:5000/data
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/stress.py
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/checkids.py
wget https://raw.githubusercontent.com/TeaCult/tcplogger-license/master/qrcode-gen.py
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"Finished downloading scripts\"}" http://192.168.5.26:5000/data
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"Generating qr-code\"}" http://192.168.5.26:5000/data
python3 qrcode-gen.py $(cat /sys/class/net/enp0s25/address)
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"Generated qr-code\"}" http://192.168.5.26:5000/data

curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"Started Stress test\"}" http://192.168.5.26:5000/data
python stress.py 6
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"Finished cpu test\"}" http://192.168.5.26:5000/data
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"Starting smartcl test\"}" http://192.168.5.26:5000/data
smartctl -t short /dev/sda
echo "Waiting for smart test to finish"
while grep -q "in progress" <(smartctl -a /dev/sda); do
    sleep 10  # Sleeps for 10 seconds before checking again
done
curl -X POST -H "Content-Type: application/json" -d "{\"$(cat /sys/class/net/enp0s25/address)-smartctl\": \"$(smartctl -a /dev/sda | tr -d '\n')\"}" http://192.168.5.26:5000/data



