# SynoPassthru

Many thanks to [@sramshaw](https://github.com/sramshaw) for the great ideas that inspired this fork.

Synology VMM is based on KVM, but it does not allow users to edit the config file manually. The only way (as I know) to passthrough a PCI device is by using "virsh attach-device", which is quite inconvenient since you have to do it every time you restart your virtual machine. Besides, some PCI devices must be attached at the very begining of the VM, manually attaching it may not always be successful.

Thus, SynoPassthru is a useful script that can automatically pass through PCI devices to a VMM virtual machine during boot-up.

## Architecture
The automation is achieved through a `qemu` hook that is triggered when a VM starts.
1.  **`deploy.sh`**: This is the main installation script. It copies all necessary scripts to `/usr/local/libvirt` and injects a hook into the Synology VMM startup sequence.
2.  **QEMU Hook**: The hook is a script located at `/etc/libvirt/hooks/qemu`. When any VM starts, this hook is executed by `libvirtd`.
3.  **`attach_detach_all.sh`**: The QEMU hook script calls this master script, passing the VM name as an argument.
4.  **User Scripts**: `attach_detach_all.sh` then executes the user-created scripts located in `/usr/local/libvirt/user/`.
5.  **`attach_detach_pci_from_vm.sh`**: Each user script calls this core script, which contains the logic to unbind the PCI device from the host and attach it to the specified guest VM using `virsh`.

## Properties
The following properties are used in the user-configurable scripts (`scripts/user/*.sh`) to define which device is passed through to which VM.

| Property  | Type     | Description                                                                                                                               |
|-----------|----------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `ADDRESS`   | `String` | The PCI address of the device to passthrough (e.g., "08:00.0"). Found using `lspci`.                                                      |
| `VENDOR`    | `String` | The vendor ID of the PCI device. Found using `lspci -n`.                                                                                  |
| `PRODUCT`   | `String` | The product ID of the PCI device. Found using `lspci -n`.                                                                                 |
| `VM_NAME`   | `String` | The name of the target VM. **Must** be the name shown by `virsh list --all`, which can differ from the name in the Synology VMM UI.       |
| `ROM`       | `String` | (Optional) The absolute path to a vBIOS ROM file for the device. This is often required for GPU passthrough. See Appendix for details.    |

## How to Use

#### 1. IOMMU Check
Ensure your hardware supports IOMMU and the target PCI device is in its own IOMMU group.
```bash
# Check for IOMMU support
dmesg | grep IOMMU

# Check IOMMU groups
./utils/iommu.sh
```

Here is the well-separated IOMMU example
```
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

#### 2. Configure User Scripts
For each PCI device you want to passthrough, create a `.sh` file in the `scripts/user/` directory. You can copy an example and edit the properties.
```bash
# Example: scripts/user/attach_my_gpu.sh

#!/bin/bash
ADDRESS="08:00.0"
VENDOR="1002"
PRODUCT="1638"
ROM="vbios_1002_1638.bin"
VM_NAME="my-vm-name-from-virsh"
export VM_NAME

if [ "$TARGET_VM" == "$VM_NAME" ]; then
    /usr/local/libvirt/attach_detach_pci_from_vm.sh "ATTACH" "$ADDRESS" "$VENDOR" "$PRODUCT" "$ROM"
fi
```

#### 3. Update Master Script
**This is a crucial step.** Edit `scripts/attach_detach_all.sh` to call the user scripts you created.
```bash
# Example: scripts/attach_detach_all.sh

#!/bin/bash
TARGET_VM="$1"
export TARGET_VM

/usr/local/libvirt/user/attach_my_gpu.sh
/usr/local/libvirt/user/attach_my_usb_controller.sh
```

#### 4. Deploy
Run the deploy script with `sudo` to install the hook and copy the scripts.
```bash
sudo ./deploy.sh
```
The passthrough will now be automated on every VM start.

## Debugging
- **`/var/log/qemu_hook.log`**: Log for the main hook script. Check for errors in hook execution.
- **`/var/log/attach_detach_pci_from_vm.log`**: Detailed log for the device attachment process. Check for `virsh` or device binding errors.

---

## Appendix: AMD iGPU Passthrough Notes

#### IOMMU group aren't well-separated
You can try enabling the ACS option in the BIOS, this usually resolves the issue.

But if you're using an AMD Zen 3 CPU with an older chipset (e.g. B350 or B450 motherboard), you may encounter an issue:
The ACS option may be deprecated for newer CPUs due to BIOS storage limitations
AM4 motherboards support up to five generations of CPUs (AMD YES!). To make this possible, some rarely used features had to be sacrificed. So if you unfortunately find that the ACS option is missing, downgrading the BIOS may help.

Take me for example — I'm using AMD Ryzen 3 5350GE with an ASRock B450M Pro4 motherboard, and there's no ACS option in the BIOS. After doing some research online, I found this thread: https://www.reddit.com/r/ASRock/comments/pfza16/deskmini_x300_bios_with_acs_enable/
It mentioned that there's a BIOS version for Asrock B450F which supports well-separated IOMMU groups! After trying B450M BIOS with the same AGESA version(1.2.0.6b), it works as well!
(Note: This BIOS version still doesn't include the ACS option, but it enables well-separated groups using the PCI ARI option instead.)

In conclusion, if you're using a different motherboard and run into the same issue, try flashing a BIOS with the same AGESA version above. If that still doesn't work... well, it's time to email the vendor and ask for it😅

#### ROM File (vBIOS)
Passing through an AMD iGPU often requires a vBIOS ROM file to ensure the guest VM can initialize the GPU correctly and to mitigate the "AMD Reset Bug."
To extract the ROM, use the `vbios` executable provided in the `utils` directory.
1.  Navigate to the repository's root directory.
2.  Run the tool. It will create a ROM file in the same directory (e.g., `vbios_xxxx.bin`).
    ```bash
    ./utils/vbios
    ```
3.  Move this file to `/usr/local/libvirt/user/` and set the `ROM` variable in your script accordingly.

#### Audio Passthrough for Stability (Error 43 Fix)
A common issue with AMD APU passthrough is a failure (often "Error 43" in Windows) if the integrated audio device is not also passed through. This is a known requirement for many Ryzen APUs.
- **Action**: You must create a **separate `.sh` script** for the iGPU's audio device, just as you did for the iGPU itself.
- **Configuration**: Edit the script with the audio device's `ADDRESS`, `VENDOR`, and `PRODUCT` IDs. The `ROM` variable can typically be left empty.
- **Enablement**: Remember to add a call to this new audio device script in `attach_detach_all.sh`.

For more technical details, refer to this [GitHub Gist comment](https://gist.github.com/matt22207/bb1ba1811a08a715e32f106450b0418a?permalink_comment_id=4955044#gistcomment-4955044) and the guide at [ryzen-gpu-passthrough-proxmox](https://github.com/isc30/ryzen-gpu-passthrough-proxmox).
