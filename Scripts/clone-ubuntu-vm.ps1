#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$SourceExportPath = "C:\Hyper-V-Lab\Exports\ubuntu-template-01"
$NewVMName = "cicd-01"
$SwitchName = "KAMIL-LAB"

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

$ExistingVM = Get-VM `
    -Name $NewVMName `
    -ErrorAction SilentlyContinue



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

if (Test-Path $NewVhdPath) {
    Write-Host "Dysk docelowy już istnieje. Pomijam ponowne kopiowanie."

    $CopiedVhdx = Get-Item -LiteralPath $NewVhdPath
}
else {
    Write-Host "Kopiowanie dysku źródłowego do: $NewVhdPath"

    Copy-Item `
        -LiteralPath $SourceVhdx.FullName `
        -Destination $NewVhdPath `
        -Force

    $CopiedVhdx = Get-Item `
        -LiteralPath $NewVhdPath
}

if ($CopiedVhdx.Length -ne $SourceVhdx.Length) {
    throw "Rozmiar skopiowanego dysku różni się od rozmiaru źródła."
}

Write-Host "Dysk maszyny '$NewVMName' został skopiowany pomyślnie."
Write-Host "Źródło: $($SourceVhdx.FullName)"
Write-Host "Kopia: $($CopiedVhdx.FullName)"
Write-Host "Rozmiar: $([math]::Round($CopiedVhdx.Length / 1GB, 2)) GB"

Write-Host
Write-Host "Sprawdzanie przełącznikua wirtualnego '$SwitchName'..."

$VirtualSwitch = Get-VMSwitch `
    -Name $SwitchName `
    -ErrorAction SilentlyContinue

if (-not $VirtualSwitch) {
    throw "Nie znaleziono przełącznika wirtualnego o nazwie '$SwitchName'."
}

Write-Host "Przełącznik wirtualny '$SwitchName' został znaleziony."

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

if ($ExistingVM) {
    Write-Host
    Write-Host "Maszyna wirtualna '$NewVMName' już istnieje. Pomijam tworzenie nowej maszyny."

    $NewVM = $ExistingVM
}

else {
    Write-Host
    Write-Host "Tworzenie maszyny wirtualnej '$NewVMName'..."

    $NewVM = New-VM @VMParameters

    Write-Host "Maszyna wirtualna '$NewVMName' została utworzona pomyślnie."
}


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
Write-Host
