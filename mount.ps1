# check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "ABORT: This script must be run as an Administrator to attach physical drives to WSL."
    Exit
}

Write-Host "=== ext4 LUKS mounter ==="

# check UAC linked connections regkey
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegKey = "EnableLinkedConnections"
$LinkedStatus = (Get-ItemProperty -Path $RegPath -Name $RegKey -ErrorAction SilentlyContinue).$RegKey

$NeedsManualSubst = $false
if ($LinkedStatus -ne 1) {
    Write-Host "`n[WARNING] The '$RegKey' registry value is not set to 1." -ForegroundColor Yellow
    Write-Host "Since this script is running with admin privileges, any drive letter mapped will NOT be visible in your standard (non-admin) Windows Explorer."
    $Choice = Read-Host "Do you still want to proceed? (Y/N)"
    if ($Choice -notmatch "^(?i)y") {
        Write-Host "aborting..." -ForegroundColor Red
        Exit
    }
    $NeedsManualSubst = $true
}

# select wsl distro
$Distro = Read-Host "`nEnter your WSL distribution name (e.g., Ubuntu, Debian)"

# read-only query: list physical drives
Write-Host "`n[QUERY] Available physical drives:"
Get-CimInstance Win32_DiskDrive | Select-Object Index, Model, Size, Partitions | Format-Table -AutoSize

$DiskIndex = Read-Host "Enter the index number of the drive you want to attach"
$DriveID = "\\.\PHYSICALDRIVE$DiskIndex"

# attach drive to WSL
Write-Host "`nAttaching $DriveID to WSL..."
wsl --mount $DriveID --bare

# read-only query: list partitions inside WSL
Write-Host "`n[QUERY] Available partitions on attached drive:"
wsl -d $Distro -u root lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT

$PartName = Read-Host "Enter the LUKS partition name to decrypt (e.g., sdb1, sdc2)"
$MapperName = "interactive_luks"

# interactively unlock LUKS
Write-Host "`nUnlocking /dev/$PartName (Please enter your LUKS passphrase)..."
wsl -d $Distro -u root cryptsetup luksOpen "/dev/$PartName" $MapperName

# mount the filesystem
$MountPoint = "/mnt/luks_ext4"
Write-Host "`nMounting to $MountPoint inside WSL..."
wsl -d $Distro -u root mkdir -p $MountPoint
wsl -d $Distro -u root mount "/dev/mapper/$MapperName" $MountPoint

# map desired drive Letter
$DriveLetter = Read-Host "`nEnter the drive letter you want to assign in Windows (e.g., Z)"
$DriveLetter = $DriveLetter.Substring(0,1).ToUpper() + ":"
$WslPath = "\\wsl.localhost\$Distro$MountPoint"

Write-Host "`nMapping $WslPath to $DriveLetter using subst..."
subst $DriveLetter $WslPath

# final status and reminder
Write-Host "`n=== mount successfully achieved ===" -ForegroundColor Green
if ($NeedsManualSubst) {
    Write-Host "REMINDER: Because your system isolates admin drives, you will not see $DriveLetter in your user explorer." -ForegroundColor Yellow
    Write-Host "To see your files, open a NORMAL (non-administrative) command prompt or PowerShell and run this exact command:" -ForegroundColor Cyan
    Write-Host "subst $DriveLetter $WslPath" -ForegroundColor Cyan
}
