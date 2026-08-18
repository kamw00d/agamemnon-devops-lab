#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$VMName = "ubuntu-template-01"
$ExportRoot = "C:\Hyper-V-Lab\Exports"
$ExportPath = "$ExportRoot\$VMName"

$VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

if (-not $VM) {
    throw "Nie znaleziono maszyny wirtualnej o nazwie '$VMName'."
}

if ($VM.State -ne 'Off') {
    throw "Maszyna wirtualna '$VMName' musi być wyłączona przed eksportem."
}

Write-Host "Maszyna $VMName istnieje i jest wyłączona. Kontynuuję eksport."

if (Test-Path $ExportPath) {
    throw "Ścieżka eksportu '$ExportPath' już istnieje."
}

New-Item `
    -ItemType Directory `
    -Path $ExportRoot `
    -Force | Out-Null

Write-Host
Write-Host "Finalizowanie nośników i kolejności rozruchu..."

$DVDDrive = Get-VMDvdDrive -VMName $VMName |
    Select-Object -First 1

if ($DVDDrive) {
    if ($DVDDrive.Path) {
        $DVDDrive |
            Set-VMDvdDrive -Path $null

        Write-Host "Obraz ISO został odłączony od napędu DVD."
    }
    else {
        Write-Host "Napęd DVD istnieje, ale obraz ISO jest już odłączony."
    }
}
else {
    Write-Host "Maszyna wirtualna nie ma napędu DVD. Pomijam odłączanie ISO."
}

$SystemDisk = Get-VMHardDiskDrive -VMName $VMName |
    Select-Object -First 1

if (-not $SystemDisk) {
    throw "Nie znaleziono dysku systemowego dla maszyny '$VMName'."
}

Set-VMFirmware `
    -VMName $VMName `
    -FirstBootDevice $SystemDisk

Write-Host "Dysk VHDX został ustawiony jako pierwsze urządzenie rozruchowe."

Write-Host
Write-Host "Kontrola nośników i kolejności rozruchu:"

Get-VMDvdDrive -VMName $VMName | Format-List Path, ControllerLocation, ControllerNumber

Write-Host "Pierwsze urzązenie rozruchowe:"

(Get-VMFirmware -VMName $VMName).BootOrder | Select-Object -First 1 | Format-List BootType, Description, Device

Write-Host
Write-Host "Rozpoczynam eksport maszyny wirtualnej '$VMName'"

$ExportParameters = @{
    VM = $VM
    Path = $ExportRoot
}

Export-VM @ExportParameters

Write-Host "Eksport maszyny wirtualnej '$VMName' został zakończony."

if (-not (Test-Path $ExportPath)) {
    throw "Eksport zakońćzył się bez utworzenia oczekiwanego katologu: $ExportPath"
}

$ExportedVhdx = @(
    Get-ChildItem `
    -Path $ExportPath `
    -Filter "*.vhdx"`
    -File `
    -Recurse
)

$ExportedConfig = @(
    Get-ChildItem `
    -Path $ExportPath `
    -Filter "*.vmcx" `
    -File `
    -Recurse
)

if ($ExportedVhdx.Count -eq 0) {
    throw "W eksporcie nie znaleziono żadnego dysku VHDX. "
}

if ($ExportedConfig.Count -eq 0) {
    throw "W eksporcie nie znaleziono żadnego pliku konfiguracyjnego VMCX. "
}

Write-Host
Write-Host "Eksport został zweryfikowany, Katalog: $ExportPath, Liczba plików VHDX: $($ExportedVhdx.Count), Liczba plików VMCX: $($ExportedConfig.Count)"

$ExportedVhdx |
    Select-Object `
        Name,
        @{ Name= "SizeGB"; Expression = {
            [math]::Round($_.Length / 1GB, 2)
        }},
        FullName |
    Format-Table -AutoSize
