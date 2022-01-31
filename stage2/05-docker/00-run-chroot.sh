#!/bin/bash -e


main(){
    cd / && \
    export SSL_CERT_FILE=/usr/lib/ssl/certs/ca-certificates.crt
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh
    sudo usermod -aG docker ${FIRST_USER_NAME}
}

main
