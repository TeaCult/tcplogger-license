/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
pacman -Sy --noconfirm stress lm_sensors dmidecode wget
sensors-detect --auto
stress -c 4 -i 4  --timeout 60 
sensors 
wget https://github.com/TeaCult/tcplogger-license/edit/master/stress.py
