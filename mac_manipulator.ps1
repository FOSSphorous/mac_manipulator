param ( [Parameter(Mandatory=$false)] [int]$Interface, [Parameter(Mandatory=$false)] [string]$Random )

function Pass-Parameters {
    Param ([hashtable]$NamedParameters)
    return ($NamedParameters.GetEnumerator()|%{"-$($_.Key) `"$($_.Value)`""}) -join " "
}

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + (Pass-Parameters $MyInvocation.BoundParameters) + " " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}

# Remainder of script here
Write-Host $CommandLine
$device = get-wmiobject -class win32_networkadapter | select-object name,macaddress,deviceid | where-object {$_.macaddress -ne $null}
if ($Interface -ge 1){
$Interface = [int]$Interface - 1
$selection = $Interface
} else {
$count = 1
$device | Select-Object name, macaddress | ForEach-Object {
    $_ |  Select-Object @{Name = 'Line'; Expression = {$count}}, *
    $count++
} | Format-Table -HideTableHeaders
$count = $count-1

$selection = Read-Host -Prompt "Select an interface (1-$count)"
while ([int]$selection -gt $count -or [int]$selection -lt 1){
$selection = Read-Host -Prompt "Your selection is invalid. Please select an interface (1-$count)"
}
$selection = [int]$selection - 1
} #$device[$selection]

function Get-MacAddr {
$least_sig_bit = '26ae'
$full_range_bit = '0123456789abcdef'
$mac_addr = -join (1 | ForEach-Object {$full_range_bit[(Get-Random -Maximum $full_range_bit.Length)]}) + -join (1 | ForEach-Object {$least_sig_bit[(Get-Random -Maximum $least_sig_bit.Length)]}) + -join (1..10 | ForEach-Object {$full_range_bit[(Get-Random -Maximum $full_range_bit.Length)]})
$mac_addr
}

if ($Random -ne 'y') {
$new_mac= Read-Host -Prompt "Write a new MAC address (or leave blank for a random one)"
$new_mac = $new_mac -replace "[^a-fA-F0-9 ]", ""
if ($new_mac.Length -ne 12){ $new_mac = "" }
} else { $new_mac = ""}
while ($new_mac -eq "") {
    $new_mac = Get-MacAddr
    Write-Host "Randomly generated MAC address: $new_mac"
    
    if ($Random -ne 'y') {
    $regenerate = Read-Host -Prompt "Generate a different one? (y/n)"
    if ($regenerate -eq "y") {
        $new_mac = ""
    }
    }
}
$new_mac = $new_mac.ToUpper()

$device_id = if ([int]$device[$selection].deviceid -lt 10){
                "000" + $device[$selection].deviceid
            } else { 
                "00" +$device[$selection].deviceid
            }

$device_name = $device[$selection].name

$RegistryPath = "HKLM:SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$device_id"
$KeyName = 'NetworkAddress'

# Bring adapter down so changes to mac address can be loaded
Disable-NetAdapter -InterfaceDescription "$device_name" -Confirm:$false
 
# Now set the mac address
New-ItemProperty -Path $RegistryPath -Name $KeyName -Value $new_mac -PropertyType String -Force

#Bring adapter back up
Enable-NetAdapter -InterfaceDescription "$device_name" -Confirm:$false