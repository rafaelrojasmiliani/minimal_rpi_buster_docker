#!/bin/bash -e


main(){
echo we are here >> "${ROOTFS_DIR}/output_my"

if [ -v WPA_COUNTRY ]; then
	echo "country=${WPA_COUNTRY}" >> "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant.conf"
fi

if [ -v WPA_ESSID ] && [ -v WPA_PASSWORD ]; then
on_chroot <<EOF
set -o pipefail
wpa_passphrase "${WPA_ESSID}" "${WPA_PASSWORD}" | tee -a "/etc/wpa_supplicant/wpa_supplicant.conf"
EOF
elif [ -v WPA_ESSID ]; then
cat >> "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant.conf" << EOL

network={
	ssid="${WPA_ESSID}"
	key_mgmt=NONE
}
EOL
fi

if [ -f "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf" ]; then
cat > "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf" << EOL
[server]
host-name=${AVAHI_HOST_NAME}
use-ipv4=yes
use-ipv6=yes
ratelimit-interval-usec=1000000
ratelimit-burst=1000

[wide-area]
enable-wide-area=yes

[publish]
publish-hinfo=no
publish-workstation=no

[reflector]
enable-reflector=yes

[rlimits]
EOL
fi
if ${WLAN_HAS_STATIC_IP}; then
cat >> "${ROOTFS_DIR}/etc/dhcpcd.conf" << EOL
interface wlan0
static ip_address=${WLAN_STATIC_IP}
static routers=${WLAN_STATIC_IP_GATEWAY}
EOL
fi
if ${ETH_HAS_STATIC_IP}; then
cat >> "${ROOTFS_DIR}/etc/dhcpcd.conf" << EOL
interface eth0
static ip_address=${ETH_STATIC_IP}
static routers=${ETH_STATIC_IP_GATEWAY}
EOL
fi



}

main
