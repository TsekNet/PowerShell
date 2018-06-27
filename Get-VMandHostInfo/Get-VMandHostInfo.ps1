 <# 
.SYNOPSIS
Gather info on all ESX hosts and VMs
.DESCRIPTION
Gather information on VM RAM/CPU/HDD/etc
Also gather info on ESX host usage, and datastores

.NOTES 
NAME: Get-VMandHostInfo.ps1
AUTHOR: Daniel Tsekhanskiy
LASTEDIT: 6/27/18
#>

#Default parameters required for the script to run
param(
    [string]$WorkingDir= (Get-Location).ProviderPath,
    [array]$VIServer = @("ESXHOST1", "ESXHOST2", "ESXHOST3"),
    [string]$userName = "",
    [string]$pass = ""
)

Function Get-VMandHostInfo {

# Disconnect any previous vCenter server connections
Disconnect-VIServer -Server * -Force -Confirm:$false -Verbose:$false | Out-Null

#Credentials that have at least read access to the vCenter servers you will be querying
$userName = "DOMAIN\USER"
$pass = 'PASS'

#Default CSS style for the report
$style = "
<style>BODY{font-family: Arial; font-size: 10pt;}
TABLE{border: 1px solid black; border-collapse: collapse;}
TH{border: 1px solid black; background: #4286f4; padding: 5px; color: white; }
TD{border: 1px solid black; padding: 5px; }
tr:nth-child(even) { background-color: #c6d7f2;}
p{margin: 0;}
</style>
<link rel='shortcut icon' type='image/x-icon' href='../favicon.ico'>
<title>VM Reports</title>
"
$ServerArray = $VIServer -join " | "

#Heading for HTML report
$PreContent = "<h2>VM Report(s) for:</h2>" + $Date + " - $($ServerArray.toUpper())<hr>"
$PreContentESX = "<h2>ESX Report(s) for:</h2>" + $Date + " - $($ServerArray.toUpper())<hr>"
$PostContent = "<hr><p align='right'>Script last run on <b>" + (Get-Date).ToShortDateString() +"</b> at <b>"+ (Get-Date).ToShortTimeString() + "</b> EST from <b>$($env:COMPUTERNAME.ToLower())</b>. Written in PowerShell by Daniel Tsekhanskiy. <a href='https://github.factset.com/portware-infrastructure/Get-ESXInfo'>Source code</a> on GitHub.</p>"

#Connect to vCenter servers
if ($userName){
Connect-VIServer $VIServer -User $userName -Password $pass | Out-Null
} else {
Connect-VIServer $VIServer -Credential $MyCredential | Out-Null
}

#Main code block
try {

#Used to count the number of VMs total
$i=1

#Query for all VMs now, to not do it multiple times later
$VMList = Get-VM

#Initialize empty array to put all VM info in later
$array = @()

#Loop through each VM from query above, get info
foreach ($VM in $VMList) {
#Query the $VIServer for snapshot Info
$Report = $VM |  Select-Object -Verbose @{n="Num";e={$i}}, Name, @{n='MemoryGB';e={"$($_.MemoryGB -as [int]) GB"}}, @{n='NumCpu';e={"$($_.NumCpu) vCPU"}}, VMHost | Sort VMHost
$HDDInfo = $VM | Get-HardDisk | Select @{n='Filename';e={$_.Filename.subString($_.Filename.IndexOf('/')+1) }}, CapacityGB

#Create a Powershell object for each VM to add to array later
$obj = New-Object -TypeName PSObject

#Add all relevant info to this object
$obj | Add-Member -MemberType NoteProperty -Name Num -Value $Report.Num
$obj | Add-Member -MemberType NoteProperty -Name Name -Value $Report.Name
$obj | Add-Member -MemberType NoteProperty -Name RAM -Value $Report.MemoryGB
$obj | Add-Member -MemberType NoteProperty -Name CPU -Value $Report.NumCpu
$obj | Add-Member -MemberType NoteProperty -Name Host -Value $Report.VMHost
$obj | Add-Member -MemberType NoteProperty -Name FileName -Value $HDDInfo.Filename
$obj | Add-Member -MemberType NoteProperty -Name CapacityGB -Value $HDDInfo.CapacityGB

#VM counter
$i++

#Add each VM into the array for output later
$array += $obj

}

#Query the $VIServer for vmhost Info
$ReportVM = Get-VMHost | Sort-Object -Property @{E={$_.MemoryUsageGB / $_.MemoryTotalGB}}, @{E={$_.CpuUsageMhz / $_.CpuTotalMhz}} -Descending | Select Name,
    @{n="RAM % Used";e={$RAM = $_.MemoryUsageGB / $_.MemoryTotalGB; if($RAM -gt 0.7) { "#color"+"{0:N2}" -f ("{0:N0}%" -f ($RAM*100) +"color#") }  else { "{0:N2}" -f ("{0:N0}%" -f ($RAM*100)) } }},
    @{n="CPU % Used";e={$CPU = $_.CpuUsageMhz / $_.CpuTotalMhz; if($CPU -gt 0.5) { "#color"+"{0:N2}" -f ("{0:N0}%" -f ($CPU*100) +"color#") }  else { "{0:N2}" -f ("{0:N0}%" -f ($CPU*100)) } }},
    @{N="Memory Used";E={"{0:N0} GB" -f ($_.MemoryUsageGB)}},
    @{N="Memory Total";E={"{0:N0} GB" -f ($_.MemoryTotalGB)}},
    @{N="CPU Count";E={$_.NumCpu}} | ConvertTo-Html -Fragment

#Query the $VIServer for datstore Info
$ReportDS = Get-Datastore | Sort-Object -Property @{E={$_.FreeSpaceGB / $_.CapacityGB}} -Descending | 
    select Name, 
    @{n="Datastore % Used";e={$DS = $_.FreeSpaceGB / $_.CapacityGB; if($DS -gt 0.7) { "#color"+"{0:N2}" -f ("{0:N0}%" -f ($DS*100) +"color#") }  else { "{0:N2}" -f ("{0:N0}%" -f ($DS*100)) } }},
    @{N="Used";E={"{0:N2}" -f ("{0:N0} GB" -f ($_.FreeSpaceGB))}},
    @{N="Capacity";E={"{0:N2}" -f ("{0:N0} GB" -f ($_.CapacityGB))}} | 
    ConvertTo-Html -Fragment

$array = $array | Select Num, Name, RAM, CPU, Host, FileName, CapacityGB | 
    ConvertTo-Html -Head $style -PreContent $PreContent -PostContent $PostContent

#Conditional formatting for snapshots that fit certain criteria        
$array = $array -replace "#color","<font color='red'><b>"
$array = $array -replace "color#","</b></font>"
$array | Out-File "c:\temp\vms.html"

#Conditional formatting for vmhosts that fit certain criteria 
$ReportVM = $ReportVM -replace "#color","<font color='red'><b>"
$ReportVM = $ReportVM -replace "color#","</b></font>"
$ReportVM | ConvertTo-Html -Fragment

#Conditional formatting for datastore that fit certain criteria 
$ReportDS = $ReportDS -replace "#color","<font color='red'><b>"
$ReportDS = $ReportDS -replace "color#","</b></font>"
$ReportDS | ConvertTo-Html -Fragment

#Convert results to an HTML report
ConvertTo-Html -Head "$style $PreContentESX" -Body "$ReportVM </br> $ReportDS" -PostContent $PostContent | 
    Out-File "c:\temp\hosts.html"
} Catch {

#Write any errors
$Error[0]
}

}

Get-VMandHostInfo
