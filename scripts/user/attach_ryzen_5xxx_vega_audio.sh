#!/bin/bash

# The PCI device you want to attach or detach
ADDRESS="08:00.1" # Remain empty to attach/detach to all VENDOR:PRODUCT devices
VENDOR="1002"
PRODUCT="1637"
ROM="/usr/local/libvirt/user/AMDGopDriver_1002_1637.rom"

# The VM you want to attach or detach (from "virsh list")
VM_NAME="591328d9-88d5-42aa-9551-bb793c3330cf"
export VM_NAME

if [ "$TARGET_VM" == "$VM_NAME" ]; then
    /usr/local/libvirt/attach_detach_pci_from_vm.sh "ATTACH" "$ADDRESS" "$VENDOR" "$PRODUCT" "$ROM"
fi
