#!/bin/bash -e

install -v -d					"${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d"
install -v -m 644 files/wait.conf		"${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d/"

install -v -d					"${ROOTFS_DIR}/etc/wpa_supplicant"
install -v -m 600 files/wpa_supplicant.conf	"${ROOTFS_DIR}/etc/wpa_supplicant/"

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

# Disable wifi on 5GHz models if WPA_COUNTRY is not set
mkdir -p "${ROOTFS_DIR}/var/lib/systemd/rfkill/"
if [ -n "$WPA_COUNTRY" ]; then
    echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-3f300000.mmcnr:wlan"
    echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-fe300000.mmcnr:wlan"
else
    echo 1 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-3f300000.mmcnr:wlan"
    echo 1 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-fe300000.mmcnr:wlan"
fi

if [ -f "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf" ]; then
cat > "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf" << EOL
[server]
host-name=${AVAHI_HOST_NAME}
use-ipv4=yes
use-ipv6=yes
allow-interfaces=${AVAHI_ALLOW_INTERFACES}
deny-interfaces=${AVAHI_DENY_INTERFACES}
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

cat > "${ROOTFS_DIR}/etc/default/dhcp-helper" <EOF
DHCPHELPER_OPTS="-s 255.255.255.255"
EOF

cat  > "${ROOTFS_DIR}/etc/systemd/system/parprouted.service" <EOF
[Unit]
Description=proxy arp routing service
Documentation=https://raspberrypi.stackexchange.com/q/88954/79866
[Service]
Type=forking
# Restart until wlan0 gained carrier
Restart=on-failure
RestartSec=5
TimeoutStartSec=30
ExecStartPre=/lib/systemd/systemd-networkd-wait-online --interface=wlan0 --timeout=6 --quiet
ExecStartPre=/bin/echo 'systemd-networkd-wait-online: wlan0 is online'
ExecStartPre=/bin/bash -c "/sbin/ip link add br0 type bridge"
ExecStartPre=/bin/bash -c "/sbin/iptables -A FORWARD -i br0  -j ACCEPT"
ExecStartPre=/bin/bash -c "/sbin/ip addr add $(ip --brief a l wlan0 | awk '{print $3}' | sed 's/...$//')/32 dev br0"
ExecStartPre=/sbin/ip link set dev br0 up
ExecStartPre=/sbin/ip link set wlan0 promisc on
ExecStart=-/usr/sbin/parprouted br0 wlan0
ExecStopPost=/sbin/ip link set wlan0 promisc off
ExecStopPost=/sbin/ip link set dev br0 down
ExecStartPre=/bin/bash -c "/sbin/ip link del br0"
[Install]
WantedBy=wpa_supplicant@wlan0.service
EOF

