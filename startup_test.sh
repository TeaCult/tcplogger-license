/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
pacman -Sy --noconfirm stress lm_sensors dmidecode wget
sensors-detect --auto
wget https://github.com/TeaCult/tcplogger-license/edit/master/stress.py
python stress.py 60
sensors
