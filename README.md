# pi-gen minimal RPI image with docker

This is a fork of [pi-gen](https://github.com/RPi-Distro/pi-gen).

## Use

1. Fill the config file
2. `sudo bash build.sh`
3. Copy the image
```BASH
unzip -p  deploy/image.zip  | dd of=DEV bs=64M conv=fsync status=progress
```
