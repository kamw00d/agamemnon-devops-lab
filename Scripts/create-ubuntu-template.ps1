#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$VMName = "ubuntu-template-01"
$SwitchName = "KAMIL-LAB"
$LabRoot = "C:\Hyper-V-Lab"

$VMPath = "$LabRoot\VMs"
$VHDPath = "$LabRoot\VHDX\$VMName.vhdx"
$ISOPath = "$LabRoot\ISO\ubuntu-24.04.4-live-server-amd64.iso"


if (-not (Test-Path $ISOPath)) {
	throw "Nie znaleziono obrazu ISO: $ISOPath"
}

if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
	throw "Nie znaleziono przełącznika Hyper-V: $SwitchName"
}


Write-Host "Kontrola zakonczona: mozna utworzyc maszyne."

$VMParameters = [ordered]@{
	Name = $VMName
	MemoryStartupBytes = 4GB
	Generation = 2
	Path = $VMPath
	NewVHDPath = $VHDPath
	NewVHDSizeBytes = 40GB
	SwitchName = $SwitchName
}

Write-Host ""
Write-Host "Planowana konfiguracja maszyny wirtualnej:"
Write-Host "Liczba parametrów: $($VMParameters.Count)"

$VMParameters.GetEnumerator() | Format-Table -Property Key, Value -AutoSize
$ExistingVM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

if ($ExistingVM) {
	Write-Host
	Write-Host "Maszyna wirtualna o nazwie '$VMName' już istnieje. Pomijam tworzenie nowej maszyny."
	$VM = $ExistingVM
} else {
	if (Test-Path $VHDPath) {
		throw "Dysk $VHDPath już istnieje, ale maszyna wirtualna '$VMName' nie istnieje."
	}

	Write-Host
	Write-Host "Tworzenie maszyny wirtualnej '$VMName'..."

	$VM = New-VM @VMParameters
	Write-Host "Maszyna wirtualna '$VMName' została utworzona."
}

if ($VM.State -ne 'Off') {
	throw "Maszyna wirtualna $VMName musi być wyłączona przed zmianą procesora i pamięci."}

Write-Host
Write-Host "Konfiguracja procesora i pamięci dla maszyny wirtualnej '$VMName'..."

Set-VMProcessor `
	-VMName $VMName `
	-Count 2

Set-VMMemory `
	-VMName $VMName `
	-DynamicMemoryEnabled $true `
	-StartupBytes 4GB

Set-VM `
	-VMName $VMName `
	-AutomaticCheckpointsEnabled $false

Write-Host "Konfiguracja procesora i pamięci dla maszyny wirtualnej '$VMName' zakończona."

Write-Host
Write-Host "Aktualna konfiguracja zasobów maszyny wirtualnej '$VMName':"

Get-VMProcessor -VMName $VMName | Format-List Count
Get-VMMemory -VMName $VMName | Format-List DynamicMemoryEnabled, Startup
Get-VM -Name $VMName | Format-List Name, State, AutomaticCheckpointsEnabled

Write-Host
Write-Host "Konfigurowanie sieci dla maszyny wirtualnej '$VMName'..."

Set-VMNetworkAdapterVlan `
	-VMName $VMName `
	-Untagged

Write-Host "Karta sieciowa została ustawiona w trybie 'Untagged' dla maszyny wirtualnej '$VMName'."

Write-Host
Write-Host "Konfigurowanie firmware i Secure Boot..."

Set-VMFirmware `
	-VMName $VMName `
	-EnableSecureBoot On `
	-SecureBootTemplate "MicrosoftUEFICertificateAuthority"

Write-Host "Secure Boot został skonfigurowany dla systemu Linux."

Write-Host
Write-Host "Aktualna konfiguracja sieci i firmware dla maszyny wirtualnej '$VMName':"

Get-VMNetworkAdapterVlan -VMName $VMName | Format-list OperationMode, AccessVlanId
Get-VMFirmware -VMName $VMName | Format-list SecureBoot, SecureBootTemplate

Write-Host
Write-Host "Dodawanie dysku instalacyjnego ISO do maszyny wirtualnej '$VMName'..."

$DVDDrive = Get-VMDvdDrive -VMName $VMName -ErrorAction SilentlyContinue | Select-Object -First 1

if ($DVDDrive) {
	Write-Host "Napęd DVD już istnieje. Aktualizuję ścieżkę do obrazu ISO."

	$DVDSetParameters = @{
		VMName = $VMName
		ControllerNumber = $DVDDrive.ControllerNumber
		ControllerLocation = $DVDDrive.ControllerLocation
		Path = $ISOPath
	}

	Set-VMDvdDrive @DVDSetParameters
	Write-Host "Ścieżka do obrazu ISO została zaktualizowana."
} else {
	Write-Host "Napęd DVD nie istnieje. Tworzę nowy napęd DVD i przypisuję obraz ISO."

	$DVDDRive = Add-VMDvdDrive `
		-VMName $VMName `
		-Path $ISOPath `
		-Passthru
	Write-Host "Napęd DVD został dodany i przypisano obraz ISO."
}

$DVDDRive = Get-VMDvdDrive -VMName $VMName | Select-Object -First 1

Set-VMFirmware `
	-VMName $VMName `
	-FirstBootDevice $DVDDRive

Write-Host "Obraz ISO został podłączony i ustawiony jako pierwsze urządzenie rozruchowe dla maszyny wirtualnej '$VMName'."

Write-Host
Write-Host "Aktualna konfiguracja napędu DVD:"

Get-VMDvdDrive -VMName $VMName | Format-List Path, ControllerNumber, ControllerLocation

Write-Host "Pierwsze urzązenie startowe:"
(Get-VMFirmware -VMName $VMName).BootOrder | Select-Object -First 1 | Format-List BootType, Description, Device
