#!/usr/bin/pkexec bash

TARGET_USER="reginaldo"
ID=$(id -u $TARGET_USER)
XDG_RUNTIME_DIR="/run/user/$ID"

sudo -u $TARGET_USER \
    env DISPLAY=":0.0" \
    XAUTHORITY="/home/$TARGET_USER/.Xauthority" \
    GTK_THEME="Greybird-dark:dark" \
    XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    HOME="/home/$TARGET_USER" \
    USER="$TARGET_USER" \
    weston --width=1280 --height=720 --shell="kiosk-shell.so" &
    
WESTON_PID=$!

while ! ls -1t $XDG_RUNTIME_DIR | egrep -m1 'wayland-[0-9]+$' ; do
    sleep 1
done

systemctl start waydroid-container.service

sudo -u $TARGET_USER \
    env DISPLAY=":0.0" \
    XAUTHORITY="/home/$TARGET_USER/.Xauthority" \
    GTK_THEME="Greybird-dark:dark" \
    XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    HOME="/home/$TARGET_USER" \
    USER="$TARGET_USER" \
    WAYLAND_DISPLAY=$(ls -1t $XDG_RUNTIME_DIR | egrep -m1 'wayland-[0-9]+$') \
    waydroid show-full-ui &
    
WAYDROID_PID=$!

while [[ -z $LINKS ]] ; do
    
    LINKS=$(ip link | egrep 'waydroid0' | cut -d' ' -f2)
    sleep 1
    
    
done

echo "Release interfaces in firewall..."

for LINK in $LINKS; do
    
    iptables -t filter -C INPUT -i ${LINK//:} -j ACCEPT || iptables -I INPUT 1 -i ${LINK//:} -j ACCEPT
    sleep 1
    
done

wait $WESTON_PID

echo "Impresion interfaces in firewall..."

for LINK in $LINKS; do
 
    iptables -D INPUT -i ${LINK//:} -j ACCEPT
    
    sleep 1
    
done

kill -s SIGTERM $WAYDROID_PID

systemctl stop waydroid-container.service
