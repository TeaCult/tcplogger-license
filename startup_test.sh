/usr/bin/pacman-key --init
/usr/bin/pacman-key --populate archlinux
pacman -Sy --noconfirm stress lm_sensors
sensors-detect --auto
stress -c 4 -i 4  --timeout 60 
sensors 
