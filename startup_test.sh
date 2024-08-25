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




