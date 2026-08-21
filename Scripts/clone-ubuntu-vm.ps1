#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$NewVMName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SourceExportPath = "C:\Hyper-V-Lab\Exports\ubuntu-template-01",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SwitchName = "KAMIL-LAB"
)

$ErrorActionPreference = "Stop"

$VMRoot = "C:\Hyper-V-Lab\VMs"
$VhdRoot = "C:\Hyper-V-Lab\VHDX"

$NewVMPath = "$VMRoot\$NewVMName"
$NewVhdPath = "$VhdRoot\$NewVMName.vhdx"

$SourceVhdx = Get-ChildItem `
    -LiteralPath $SourceExportPath `
    -Filter *.vhdx `
    -File `
    -Recurse |
    Select-Object -First 1


if (-not $SourceVhdx) {
    throw "Nie znaleziono dysku VHDX w eksporcie: $SourceExportPath"
}

Write-Host
Write-Host "Sprawdzanie przełącznika wirtualnego '$SwitchName'..."

$VirtualSwitch = Get-VMSwitch `
    -Name $SwitchName `
    -ErrorAction SilentlyContinue

if (-not $VirtualSwitch) {
    throw "Nie znaleziono przełącznika wirtualnego o nazwie '$SwitchName'."
}

Write-Host "Przełącznik wirtualny '$SwitchName' został znaleziony."

$ExistingVM = Get-VM `
    -Name $NewVMName `
    -ErrorAction SilentlyContinue

if ($ExistingVM) {
    throw "Maszyna wirtualna o nazwie '$NewVMName' już istnieje. Przerywam, aby uniknąć nadpisania istniejącej maszyny."
}

if (Test-Path -LiteralPath $NewVhdPath) {
    throw "Dysk docelowy '$NewVhdPath' już istnieje. Przerywam, aby uniknąć nadpisania istniejącego dysku."
}

Write-Host "Źrodłowy dysk:"
Write-Host $SourceVhdx.FullName

Write-Host
Write-Host "Planowany klon:"
Write-Host "Nazwa VM: $NewVMName"
Write-Host "Ścieżka VM: $NewVMPath"
Write-Host "Ścieżka VHDX: $NewVhdPath"
Write-Host "Przełącznik: $SwitchName"

Write-Host
Write-Host "Kopiowanie dysku źrodłowego dla maszyny wirtualnej '$NewVMName'..."

New-Item `
    -ItemType Directory `
    -Path $VhdRoot `
    -Force | Out-Null

New-Item `
    -ItemType Directory `
    -Path $VMRoot `
    -Force | Out-Null

Write-Host "Kopiowanie dysku źródłowego do: $NewVhdPath"

Copy-Item `
    -LiteralPath $SourceVhdx.FullName `
    -Destination $NewVhdPath `

$CopiedVhdx = Get-Item `
    -LiteralPath $NewVhdPath

if ($CopiedVhdx.Length -ne $SourceVhdx.Length) {
    throw "Rozmiar skopiowanego dysku różni się od rozmiaru źródła."
}

Write-Host "Dysk maszyny '$NewVMName' został skopiowany pomyślnie."
Write-Host "Źródło: $($SourceVhdx.FullName)"
Write-Host "Kopia: $($CopiedVhdx.FullName)"
Write-Host "Rozmiar: $([math]::Round($CopiedVhdx.Length / 1GB, 2)) GB"

$VMParameters = [ordered]@{
    Name = $NewVMName
    Generation = 2
    MemoryStartupBytes = 4GB
    VHDPath = $NewVhdPath
    Path = $NewVMPath
    SwitchName = $SwitchName
}

Write-Host
Write-Host "Parametry maszyny przekazywane do New-VM:"

$VMParameters.GetEnumerator() | Format-Table Key, Value -AutoSize

Write-Host
Write-Host "Tworzenie maszyny wirtualnej '$NewVMName'..."

$NewVM = New-VM @VMParameters

Write-Host "Maszyna wirtualna '$NewVMName' została utworzona pomyślnie."

if ($NewVM.State -ne "Off") {
    throw "Maszyna '$NewVMName' musi być wyłaczona przed konfiguracją sprzętu."
}

Write-Host
Write-Host "Konfigurowanie zasobów maszyny '$NewVMName'..."

Set-VMProcessor `
    -VMName $NewVMName `
    -Count 2

Set-VMMemory `
    -VMName $NewVMName `
    -DynamicMemoryEnabled $false `
    -StartupBytes 4GB

Set-VM `
    -Name $NewVMName `
    -AutomaticCheckpointsEnabled $false

Write-Host "Procesor, pamięc i checkpointy zostały skonfigurwane."

Write-Host
Write-Host "Aktualna konfiguracja maszyny '$NewVMName':"

Get-VM -Name $NewVMName | Format-List `
    Name,
    State,
    Generation,
    ProcessorCount,
    MemoryStartup

Get-VMHardDiskDrive -VMName $NewVMName | Format-List `
    Path,
    ControllerType,
    ControllerNumber,
    ControllerLocation

Get-VMNetworkAdapter -VMName $NewVMName | Format-List `
    Name,
    SwitchName,
    Status,
    MacAddress,
    DynamicMacAddressEnabled
