#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31mPlease use sudo to run this script!\033[0m"
    exit 1
fi

mkdir -p /usr/local/libvirt
rm -rf /usr/local/libvirt/*
cp -r "$SCRIPT_DIR/scripts/"* /usr/local/libvirt/
chmod 755 /usr/local/libvirt/*
chown root:root /usr/local/libvirt/*

# This script will run once when system boot up, so that we can setup our Qemu Hook during it executing
FILE="/var/packages/Virtualization/conf/systemd/insert_libvirtd_ko.sh"
CONTENT="""
# Hook for passthrough PCIe device
mkdir -p /etc/libvirt/hooks/
cp /usr/local/libvirt/qemu /etc/libvirt/hooks/qemu
"""
IFS=$'\n'
for line in $CONTENT; do
    grep -Fxq "$line" "$FILE" || echo "$line" >> "$FILE"
done

# Run once for debug purpose
bash -c "$CONTENT"
