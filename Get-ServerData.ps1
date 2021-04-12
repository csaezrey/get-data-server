#Conexiones para conexiones RPC. Este ejemplo asume mismo usuario y clave.
$user = "username"
$password = ConvertTo-SecureString "password" -AsPlainText -Force 
$credential = New-Object System.Management.Automation.PSCredential ($user, $password)

#Función para escribir archivos CSV con cabecera
function Write-File {
    param (
		$path,
		$pathTemp
        	$header,
    )
	Get-Content -Path $pathTemp    | Select -Skip 1 |	ConvertFrom-Csv -Header ("Servidor"+$delimited+$header)		| Export-Csv -Path $path    -Delimiter $delimited -NoTypeInformation
	Remove-Item -path $pathTemp
	$CSV = Get-Content -Path $path		| Foreach {$_ -replace '"', ""}  
	Set-Content -Path  $path -Value $CSV
}

#Variables generales
$date=Get-Date -Format yyyyMMddHHmm
$delimited = ";"

#Variables de rutas 
$servers = "MyServer1","MyServer2","MyServer3"
$localServer="MyServer1"
$path = "C:\path\"

#Archivos temporales (sin cabecera)
$pathOSTemp=$path+"OperatingSystemTEMP.csv"
$pathCPUTemp=$path+"ProcessorTEMP.csv"
$pathDiskTemp=$path+"DiskTEMP.csv"

#Archivos finales
$pathOS = $pathOSTemp -replace "TEMP", "" 
$pathCPU = $pathCPUTemp -replace "TEMP", "" 
$pathDisk = $pathDiskTemp -replace "TEMP", "" 

#Crea ficheros vacios
Set-Content -Path  $pathOSTemp -Value ""
Set-Content -Path  $pathCPUTemp -Value ""
Set-Content -Path  $pathDiskTemp -Value ""

#Ordenar lista de servidores
$servers = $servers | Sort-Object | Get-Unique

Foreach ($s in $servers)
{		

	#Obtener datos del servidor. De ser remoto se asigna la credencial.
	if($localServer -eq $s){
		$os = Get-WmiObject Win32_OperatingSystem -ComputerName $s 
		$cpus = Get-WmiObject Win32_Processor -ComputerName $s 
		$disks = Get-WmiObject Win32_logicaldisk -ComputerName $s
	}else{
		$os = Get-WmiObject Win32_OperatingSystem -ComputerName $s -Credential $credential
		$cpus = Get-WmiObject Win32_Processor -ComputerName $s -Credential $credential
		$disks = Get-WmiObject Win32_logicaldisk -ComputerName $s -Credential $credential
	}
	
	#Obtener valores Sistema Operativo
	$hostEntry= [System.Net.Dns]::GetHostByName($s)
	$osValue = $s + $delimited+$hostEntry.AddressList[0].IPAddressToString+$delimited+$os.Version +$delimited+ $os.OSArchitecture +$delimited+[math]::round( $os.TotalVirtualMemorySize / 1MB, 2)+$delimited+ [math]::round( $os.FreeVirtualMemory / 1MB, 2)+$delimited+ ([math]::round( $os.TotalVirtualMemorySize / 1MB, 2) -[math]::round( $os.FreeVirtualMemory / 1MB, 2) )+$delimited+[math]::round( $os.FreePhysicalMemory / 1MB, 2) +$delimited+ [math]::round( $os. TotalVisibleMemorySize / 1MB, 2)+$delimited+ [math]::round( $os. TotalSwapSpaceSize / 1MB, 2) +$delimited+[math]::round( $os. SizeStoredInPagingFiles / 1MB, 2)+$delimited+ $os.NumberOfProcesses +$delimited+ $os.NumberOfUsers +$delimited+ $os.NumberOfLicensedUsers +$delimited+ $os.Status+$delimited+$date
	Add-Content -Path $pathOSTemp  -Value $osValue
	
	#Obtenemos valores CPU
	Foreach ($cpu in $cpus)
	{
		$cpuName= $cpu.Name -replace "," , "" 
		$cpuValue=$s +$delimited+$cpu.DeviceID+$delimited+$cpuName+$delimited+ $cpu.NumberOfCores+$delimited+ $cpu.LoadPercentage+$delimited+ $cpu.MaxClockSpeed+$delimited+$date
		Add-Content -Path $pathCPUTemp  -Value $cpuValue
	}
	
	#Obtenemos valores disco
	Foreach ($disk in $disks)
	{
		$diskValue=$s +$delimited+$disk.DeviceID+$delimited+$disk.DriveType+$delimited+([math]::round( $disk.Size / 1MB, 2)/1024)+$delimited+ ([math]::round( $disk.FreeSpace / 1MB, 2)/1024)+$delimited+(([math]::round( $disk.Size / 1MB, 2)/1024) - ([math]::round( $disk.FreeSpace / 1MB, 2)/1024))+$delimited+$date
 		Add-Content -Path $pathDiskTemp  -Value $diskValue	
	}
}

#Escribe archivos finales con cabecera
Write-File $pathOS $pathOSTemp "IP"+$delimited+"Version"+$delimited+"Architectura"+$delimited+"Memoria Virtual (GB)"+$delimited+"Memoria Virtual libre (GB)"+$delimited+"Memoria Virtual ocupada (GB)"+$delimited+"Memoria Fisica Libre (GB)"+$delimited+"Memoria Visible"+$delimited+"Swamp"+$delimited+"Memoria en paginacion"+$delimited+"Total Procesos"+$delimited+"Total Usuarios"+$delimited+"Total Usuarios Licenciados"+$delimited+"Estado"+$delimited+"FechaEjecucion"
Write-File $pathCPU $pathCPUTemp "IdentificadorDispositivo"+$delimited+"Nombre"+$delimited+"Nucleos"+$delimited+"PorcentajeCarga"+$delimited+"MaximaVelocidadReloj"+$delimited+"FechaEjecucion"
Write-File $pathDisk $pathDiskTemp "ID Dispositivo"+$delimited+"Tipo"+$delimited+"EspacioTotal (GB)"+$delimited+"Espaciolibre (GB)"+$delimited+"EspacioUtilizado (GB)"+$delimited+"FechaEjecucion"
