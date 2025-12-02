#!/bin/bash
set -x  # Enable debug mode
exec >> /var/log/attach_detach_pci_from_vm.log 2>&1

OP="$1"
TARGET_ADDRESS="$2"
VENDOR="$3"
PRODUCT="$4"
ROM="$5"

ADDRESSES=($(lspci -n | grep $VENDOR:$PRODUCT | awk '{print $1}'))
for ADDRESS in "${ADDRESSES[@]}"; do
    if [ "$ADDRESS" != "$TARGET_ADDRESS" ] && [ ! -z "$TARGET_ADDRESS" ]; then
        continue
    fi
    echo "0000:$ADDRESS" > /sys/bus/pci/devices/0000:$ADDRESS/driver/unbind;
done

modprobe vfio_pci ids=$VENDOR:$PRODUCT
echo $VENDOR $PRODUCT > /sys/bus/pci/drivers/vfio-pci/new_id
for ADDRESS in "${ADDRESSES[@]}"; do
    if [ "$ADDRESS" != "$TARGET_ADDRESS" ] && [ ! -z "$TARGET_ADDRESS" ]; then
        continue
    fi

    DOMAIN=0x0000
    FUNC=`echo $ADDRESS | awk -F[.:] '{print $3}' | echo 0x$(</dev/stdin)`
    SLOT=`echo $ADDRESS | awk -F[.:] '{print $2}' | echo 0x$(</dev/stdin)`
    BUS=` echo $ADDRESS | awk -F[.:] '{print $1}' | echo 0x$(</dev/stdin)`

    cp /usr/local/libvirt/vm_template.xml /usr/local/libvirt/$ADDRESS.xml
    sed -i "s|\[DOMAIN\]|$DOMAIN|g" /usr/local/libvirt/$ADDRESS.xml
    sed -i "s|\[BUS\]|$BUS|g" /usr/local/libvirt/$ADDRESS.xml
    sed -i "s|\[SLOT\]|$SLOT|g" /usr/local/libvirt/$ADDRESS.xml
    sed -i "s|\[FUNC\]|$FUNC|g" /usr/local/libvirt/$ADDRESS.xml
    if [ -z $ROM ]; then
        sed -i "s|\[ROM\]||g" /usr/local/libvirt/$ADDRESS.xml
    else
        sed -i "s|\[ROM\]|<rom file='/usr/local/libvirt/user/$ROM'/>|g" /usr/local/libvirt/$ADDRESS.xml
    fi

    if [ $OP == "ATTACH" ]; then
        virsh attach-device $VM_NAME /usr/local/libvirt/$ADDRESS.xml --current
    elif [ $OP == "DETACH" ]; then
        virsh detach-device $VM_NAME /usr/local/libvirt/$ADDRESS.xml --current
    fi
    cat /usr/local/libvirt/$ADDRESS.xml
    rm /usr/local/libvirt/$ADDRESS.xml
done
virsh qemu-monitor-command $VM_NAME --hmp info pci
