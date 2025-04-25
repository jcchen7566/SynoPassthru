# SynoPassthru
Many thanks to [@sramshaw](https://github.com/sramshaw) for the great ideas that inspired this fork.

Synology VMM is based on KVM, but it does not allow users to edit the config file manually. The only way (as I know) to passthrough a PCI device is by using "virsh attach-device", which is quite inconvenient since you have to do it every time you restart your virtual machine. Besides, some PCI devices must be attached at the very begining of the VM, manually attaching it may not always be successful.

Thus, SynoPassthru is a useful script that can automatically pass through PCI devices to a VMM virtual machine during boot-up.

## How To
#### 1. IOMMU support check

First, you need to verify if passthrough is supported on your platform. 
```
root@DSM7:~# dmesg | grep IOMMU
[   29.046464] pci 0000:00:00.2: AMD-Vi: IOMMU performance counters supported
[   31.780077] pci 0000:00:00.2: AMD-Vi: Found IOMMU cap 0x40
[   32.800487] perf/amd_iommu: Detected AMD IOMMU #0 (2 banks, 4 counters/bank).
[   33.636767] AMD-Vi: AMD IOMMUv2 driver by Joerg Roedel <jroedel@suse.de>
```
As shown in the example above, dmesg should display the IOMMU keyword, and the driver must be loaded without any error.  
_(Tips: If you're using XPEnology, switch to the SA6400 machine for better virtualization support)_


#### 2. IOMMU group check

The PCI device you want to passthrough must be in its own separate IOMMU group. You can use [iommu.sh](https://github.com/jcchen7566/SynoPassthru/blob/main/utils/iommu.sh) to check:
```
root@DSM7:~# ./iommu.sh
IOMMU Group 17
        08:00.4 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Renoir/Cezanne USB 3.1 [1022:1639]
IOMMU Group 7
        00:08.2 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Renoir Internal PCIe GPP Bridge to Bus [1022:1635]
IOMMU Group 15
        08:00.2 Encryption controller [1080]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 10h-1fh) Platform Security Processor [1022:15df]
IOMMU Group 5
        00:08.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Renoir PCIe Dummy Host Bridge [1022:1632]
IOMMU Group 13
        08:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Cezanne [Radeon Vega Series / Radeon Vega Mobile Series] [1002:1638] (rev dd)
IOMMU Group 3
        00:02.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Renoir/Cezanne PCIe GPP Bridge [1022:1634]
IOMMU Group 11
        02:00.0 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] 400 Series Chipset USB 3.1 xHCI Compliant Host Controller [1022:43d5] (rev 01)
        02:00.1 SATA controller [0106]: Advanced Micro Devices, Inc. [AMD] 400 Series Chipset SATA Controller [1022:43c8] (rev 01)
        02:00.2 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] 400 Series Chipset PCIe Bridge [1022:43c6] (rev 01)
        03:00.0 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] 400 Series Chipset PCIe Port [1022:43c7] (rev 01)
        03:01.0 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] 400 Series Chipset PCIe Port [1022:43c7] (rev 01)
        03:04.0 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] 400 Series Chipset PCIe Port [1022:43c7] (rev 01)
        05:00.0 Ethernet controller [0200]: Realtek Semiconductor Co., Ltd. RTL8111/8168/8211/8411 PCI Express Gigabit Ethernet Controller [10ec:8168] (rev 15)
        06:00.0 Ethernet controller [0200]: Mellanox Technologies MT27500 Family [ConnectX-3] [15b3:1003]
IOMMU Group 1
        00:01.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Renoir PCIe GPP Bridge [1022:1633]
IOMMU Group 18
        08:00.6 Audio device [0403]: Advanced Micro Devices, Inc. [AMD] Family 17h/19h/1ah HD Audio Controller [1022:15e3]
IOMMU Group 8
        00:14.0 SMBus [0c05]: Advanced Micro Devices, Inc. [AMD] FCH SMBus Controller [1022:790b] (rev 51)
        00:14.3 ISA bridge [0601]: Advanced Micro Devices, Inc. [AMD] FCH LPC Bridge [1022:790e] (rev 51)
IOMMU Group 16
        08:00.3 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Renoir/Cezanne USB 3.1 [1022:1639]
IOMMU Group 6
        00:08.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Renoir Internal PCIe GPP Bridge to Bus [1022:1635]
IOMMU Group 14
        08:00.1 Audio device [0403]: Advanced Micro Devices, Inc. [AMD/ATI] Renoir Radeon High Definition Audio Controller [1002:1637]
IOMMU Group 4
        00:02.2 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Renoir/Cezanne PCIe GPP Bridge [1022:1634]
IOMMU Group 12
        07:00.0 Non-Volatile memory controller [0108]: Intel Corporation SSD DC P4101/Pro 7600p/760p/E 6100p Series [8086:f1a6] (rev 03)
IOMMU Group 2
        00:02.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Renoir PCIe Dummy Host Bridge [1022:1632]
IOMMU Group 20
        09:00.1 SATA controller [0106]: Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode] [1022:7901] (rev 81)
IOMMU Group 10
        01:00.0 Serial Attached SCSI controller [0107]: Broadcom / LSI SAS2008 PCI-Express Fusion-MPT SAS-2 [Falcon] [1000:0072] (rev 03)
IOMMU Group 0
        00:01.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Renoir PCIe Dummy Host Bridge [1022:1632]
IOMMU Group 19
        09:00.0 SATA controller [0106]: Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode] [1022:7901] (rev 81)
IOMMU Group 9
        00:18.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Cezanne Data Fabric; Function 0 [1022:166a]
        00:18.1 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Cezanne Data Fabric; Function 1 [1022:166b]
        00:18.2 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Cezanne Data Fabric; Function 2 [1022:166c]
        00:18.3 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Cezanne Data Fabric; Function 3 [1022:166d]
        00:18.4 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Cezanne Data Fabric; Function 4 [1022:166e]
        00:18.5 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Cezanne Data Fabric; Function 5 [1022:166f]
        00:18.6 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Cezanne Data Fabric; Function 6 [1022:1670]
        00:18.7 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Cezanne Data Fabric; Function 7 [1022:1671]
```
As shown above, I can passthrough "08:00.0 VGA compatible controller" because it is in its own IOMMU group. However, "05:00.0 Ethernet controller" cannot be passed through unless all devices in IOMMU Group 11 are passed through together.  

#### (Option) 3. IOMMU group aren't well-separated
You can try enabling the **ACS option** in the BIOS, this usually resolves the issue.  
  
But if you're using an AMD Zen 3 CPU with an older chipset (e.g. B350 or B450 motherboard), you may encounter an issue:  
_**The ACS option may be deprecated for newer CPUs due to BIOS storage limitations**_  
AM4 motherboards support up to five generations of CPUs (AMD YES!). To make this possible, some rarely used features had to be sacrificed. So if you unfortunately find that the ACS option is missing, downgrading the BIOS may help.  

Take me for example — I'm using AMD Ryzen 3 5350GE with an ASRock B450M Pro4 motherboard, and there's no ACS option in the BIOS. After doing some research online, I found this thread: https://www.reddit.com/r/ASRock/comments/pfza16/deskmini_x300_bios_with_acs_enable/  
It mentioned that there's a BIOS version for Asrock B450F which supports well-separated IOMMU groups! After trying B450M BIOS with the same **AGESA version(1.2.0.6b)**, it works as well!  
_(Note: This BIOS version still doesn't include the ACS option, but it enables well-separated groups using the PCI ARI option instead.)_  

In conclusion, if you're using a different motherboard and run into the same issue, try flashing a BIOS with the same AGESA version above. If that still doesn't work... well, it's time to email the vendor and ask for it😅

#### 4. Passthrough PCI device to VM


