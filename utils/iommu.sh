#!/bin/bash

for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
    echo "IOMMU Group $(basename "$iommu_group")";
    for device in $(ls "$iommu_group"/devices/); do
        echo -e "\t$(lspci -nns "$device")";
    done;
done;
