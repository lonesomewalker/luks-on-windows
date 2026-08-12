# LUKS on Windows

```
██╗     ██╗   ██╗██╗  ██╗███████╗
██║     ██║   ██║██║ ██╔╝██╔════╝
██║     ██║   ██║█████╔╝ ███████╗
██║     ██║   ██║██╔═██╗ ╚════██║   on Windows
███████╗╚██████╔╝██║  ██╗███████║
╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
```

## Overview
An interactive PowerShell toolkit designed to safely mount and decrypt LUKS-encrypted ext4 partitions natively within Windows 11 utilizing the Windows Subsystem for Linux (WSL2).

Since Windows does not natively support LUKS or the ext4 filesystem, bridging physical hardware to a virtualized Linux kernel is required. These scripts eliminate the need for dangerous, unmaintained third-party GUI tools by safely orchestrating WSL2 hardware attachment, LUKS decryption, ext4 mounting, and Windows drive mapping.

## Features
* **interactive CLI:** Step-by-step prompts to select your WSL distribution, physical drive, and target partition without hardcoding sensitive variables.
* **safety first:** Enforces Administrator privileges and strictly validates the unmount sequence to prevent filesystem corruption.
* **UAC awareness:** Detects the `EnableLinkedConnections` registry state and warns you if standard users won't be able to see the mounted drive letter.
* **native Windows mapping:** Uses `subst` to map the decrypted WSL volume directly to a Windows drive letter (e.g., `Z:\`).

## Prerequisites
* **Windows 11** with **WSL2** installed and functional.
* A Linux distribution installed in WSL (e.g., Ubuntu, Debian) with `cryptsetup` installed (`sudo apt install cryptsetup`).
* Administrator privileges on the Windows host.

## Usage

### 1. Mounting the partition (`mount.ps1`)
1. open PowerShell **as an administrator**.
2. run the script: `.\mount.ps1`
3. follow the on-screen prompts to:
   * select your WSL distribution.
   * identify your physical drive index.
   * choose the LUKS partition name.
   * enter your LUKS decryption passphrase.
   * assign a Windows drive letter.

### 2. Unmounting the partition (`unmount.ps1`)
**crucial:** ALWAYS unmount using the script to prevent data corruption. Do NOT just pull the drive out or close the WSL terminal.
1. open PowerShell **as an administrator**.
2. run the script: `.\unmount.ps1`
3. follow the prompts to cleanly remove the mapped drive letter, unmount the ext4 filesystem, lock the LUKS container again, and detach the physical drive.

## Limitations
Due to Windows User Account Control (UAC) isolation, drive letters mapped by an Administrator are not visible to standard user processes (like Windows Explorer) unless `EnableLinkedConnections` is enabled in the registry. The mount script detects this and provides instructions on how to manually map the drive in your user session if needed.
Also USB devices have some limitations.

## Future versions
A GO based version with graphical interface is planned in the future.
USB problems will be solved.
