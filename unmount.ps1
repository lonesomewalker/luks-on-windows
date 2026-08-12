# enforce admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "ABORT: This script must be run with administrative privileges to detach physical drives from WSL."
    Exit
}

Write-Host "=== ext4 LUKS unmounter ==="

$DriveLetter = Read-Host "Enter the mapped drive letter to remove (e.g., Z)"
$DriveLetter = $DriveLetter.Substring(0,1).ToUpper() + ":"

Write-Host "`nRemoving mapped drive letter $DriveLetter..."
subst $DriveLetter /D
Write-Host "(If you mapped this manually in a standard user session, you must also run 'subst $DriveLetter /D' in a non-administrative terminal)." -ForegroundColor Yellow

$Distro = Read-Host "`nEnter your WSL distribution name (e.g., Ubuntu, Debian)"
$DiskIndex = Read-Host "Enter the physical drive index to detach"
$DriveID = "\\.\PHYSICALDRIVE$DiskIndex"
$MapperName = "interactive_luks"
$MountPoint = "/mnt/luks_ext4"

Write-Host "`nUnmounting ext4 filesystem inside WSL..."
wsl -d $Distro -u root umount $MountPoint

Write-Host "Safely locking LUKS container again..."
wsl -d $Distro -u root cryptsetup luksClose $MapperName

Write-Host "Detaching physical drive from WSL..."
wsl --unmount $DriveID

Write-Host "`n=== Drive is now safely locked, unmounted, and detached ===" -ForegroundColor Green