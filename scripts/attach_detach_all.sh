#!/bin/bash

# Debug log
rm -rf /var/log/attach_detach_pci_from_vm.log

TARGET_VM="$1"
export TARGET_VM

#/usr/local/libvirt/user/attach_usb_controller.sh
#/usr/local/libvirt/user/attach_ryzen_5xxx_vega_audio.sh
#/usr/local/libvirt/user/attach_ryzen_5xxx_vega_gpu.sh
#/usr/local/libvirt/user/detach_vmvga.sh
