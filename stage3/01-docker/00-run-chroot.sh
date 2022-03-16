#!/bin/bash -e


main(){
    cd / && \
    export SSL_CERT_FILE=/usr/lib/ssl/certs/ca-certificates.crt
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh
    sudo usermod -aG docker ${FIRST_USER_NAME}

    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends -o \
        Dpkg::Options::="--force-confnew" \
        tshark dhcp-helper parprouted
    git clone https://github.com/devplayer0/docker-net-dhcp.git /opt/docker-net-dhcp
 


cat > "/etc/default/dhcp-helper" << EOF
DHCPHELPER_OPTS="-s 255.255.255.255"
EOF
systemctl enable dhcp-helper.service

echo "net.ipv4.ip_forward=1" >> "/etc/sysctl.conf" 

cat  > "/lib/systemd/system/wifibridge.service" << EOF
[Unit]
Description=proxy arp routing service for wifi bridge
Documentation=https://raspberrypi.stackexchange.com/q/88954/79866
After=network.target
[Service]
Type=forking
ExecStartPre=/bin/bash -c "ip link add brwifi type bridge"
ExecStartPre=/bin/bash -c "ip link set wlan0 promisc on"
ExecStartPre=/bin/bash -c "ip link set dev brwifi up"
ExecStartPre=/bin/bash -c "ip addr add \$(ip --brief a l wlan0 | awk '{print \$3}' | sed 's/...$//')/32 dev brwifi"
ExecStartPre=/bin/bash -c "iptables -A FORWARD -i brwifi  -j ACCEPT"
ExecStart=/bin/bash -c "/usr/sbin/parprouted brwifi wlan0"
ExecStopPost=/bin/bash -c "ip link set wlan0 promisc off"
ExecStopPost=/bin/bash -c "ip link set dev brwifi down"
ExecStopPost=/bin/bash -c "ip link del dev brwifi"
[Install]
WantedBy=multi-user.target
EOF

systemctl enable wifibridge.service


cat  > "/lib/systemd/system/ethbridge.service" << EOF
[Unit]
Description=Eth0 Bridge
After=network.target
[Service]
Type=oneshot
ExecStart=/bin/bash -c "ip link add breth type bridge; ip link set breth up; ip link set eth0 promisc on; ip link set eth0 master breth; iptables -A FORWARD -i breth -j ACCEPT"
[Install]
WantedBy=multi-user.target
EOF

systemctl enable ethbridge.service
}

main
