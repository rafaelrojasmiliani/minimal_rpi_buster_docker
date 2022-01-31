#!/bin/bash -e


main(){
    cd / && \
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh
    sudo usermod -aG docker ${FIRST_USER_NAME}
}

main
