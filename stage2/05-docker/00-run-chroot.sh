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
        tshark
    #yes | docker plugin install ghcr.io/devplayer0/docker-net-dhcp:release-linux-arm-v7
}

main
