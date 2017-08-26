 <# 
    .SYNOPSIS
     Automatically generate HTML snapshot reports for VM's older than a certain age

    .NOTES 
     NAME: Get-Snapshot.ps1
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 8/22/17
#>

param([string]$WorkingDir= (Get-Location).ProviderPath)

#region Global Variables
$Script:ProgramVersion = "0.5"
$Script:ExitCode = "0"
$Script:TimeStamp = Get-Date -Format yyyy-MM-dd_HH-mm-ss
#end region

#region Functions
Function LogMsg{
	#Arguments
	param ($sLogText,$ForegroundColor,$BackgroundColor)
	<#
		.SYNOPSIS
			Replacement for the Write-Host Cmdlet that also writes to a log file.

		.DESCRIPTION
			Replacement for the Write-Host Cmdlet that also writes to a log file.
			Log file name is determined by script name and date.

		.PARAMETER  $sLogText
			Text to be logged and Write-Host'ed

		.PARAMETER  $ForegroundColor
			Takes any valid Write-Host -ForegroundColor values (Optional)
			
		.PARAMETER  $BackgroundColor
			Takes any valid Write-Host -BackgroundColor values (Optional)

		.EXAMPLE
			PS C:\> LogMsg "Write this text to screen and log"

		.EXAMPLE
			PS C:\> LogMsg "Write this Blue text to screen and log" -ForegroundColor Blue

		.INPUTS
			System.String

		.OUTPUTS
			System.String
	#>

	#Simple function for logging to a text file. 
	#Takes text string and color as an optional parameter
	
	$CurDate = Get-Date
	
	#Echo to console
	if ($ForegroundColor -and $BackgroundColor)
	{
		Write-Host "$CurDate "$sLogText"" -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
	} 
	elseif ($ForegroundColor)
	{
		Write-Host "$CurDate "$sLogText"" -ForegroundColor $ForegroundColor
	}
	elseif ($BackgroundColor)
	{
		Write-Host "$CurDate "$sLogText"" -BackgroundColor $BackgroundColor
	}
	else
	{
		Write-Host "$CurDate "$sLogText""
	}
	
	$Day = $CurDate.day
	$Month = $CurDate.Month
	$Year = $CurDate.Year
	
	#Write to log file
	$ScriptPath = $myInvocation.ScriptName
	if($ScriptPath -match '(\w+)\.ps1$')
	{
		#Write-Host "Match Found!"
		#$Matches
		$ScriptName = $($Matches[1])
	}
	else
	{
		#Write-Host "Match Not Found!"
		$ScriptName = "UnknownCallingScript"
	}
	
    $global:sLogDir = "C:\Windows\System32\~~COMPANYNAME~\Logs\$($ScriptName)_$Year-$Month-$Day.log"
	
    Out-File -FilePath $sLogDir -InputObject "$CurDate $sLogText" -Append
}

Function LogFileCleanup {
    $CurDate = Get-Date
    $Day = $CurDate.day
	$Month = $CurDate.Month 
	$Year = $CurDate.Year
	$ScriptPath = $myInvocation.ScriptName
	if($ScriptPath -match '(\w+)\.ps1$')
	    {$ScriptName = $($Matches[1])}
	else{$ScriptName = "UnknownCallingScript"}
   Remove-Item C:\Windows\System32\~~COMPANYNAME~\Logs\$($ScriptName)* -Exclude *_$Year-$Month-*.log
}

Function SnapshotEmail {

Disconnect-VIServer * -Confirm:$false | Out-Null

#Define static variables
$VIServer = @("Server1", "Server2")
$Date = (Get-Date).ToShortDateString()

$User = "DOMAIN\Username"
$PW = "Password"

#Default CSS style for the report
$style = "
<style>BODY{font-family: Arial; font-size: 10pt;}
TABLE{border: 1px solid black; border-collapse: collapse;}
TH{border: 1px solid black; background: #4286f4; padding: 5px; color: white; }
TD{border: 1px solid black; padding: 5px; }
tr:nth-child(even) { background-color: #c6d7f2;}
</style>
"
$ServerArray = $VIServer -join " | "

#Heading
$PreContent = "<h2>Snapshot Report(s) for " + $Date + " - $($ServerArray.toUpper()) </h2><br>"

#Connect to vCenter servers
Connect-VIServer $VIServer -User $User -Password $PW | Out-Null

#Log when connected
LogMsg "Connected to $ServerArray"

try {

#Initial Query to the $VIServer
$Report = Get-VM | Get-Snapshot | Where {$_.Created -lt (Get-Date).AddDays(-7)} | Sort-Object -Property SizeGB,VM -Descending | 
    Select @{n="Hostname";e={$_.VM}}, 
    @{n="Size";e={$HDD = $_.SizeGB; if( $HDD -gt 25) { "#color"+"{0:N0} GB" -f ($HDD)+"color#" }  else { "{0:N0} GB" -f ($HDD) } }}, 
    @{n="Age";e={$Age = (((Get-Date)-$_.Created).Days+1); if( $Age -gt 365) { "#color"+"{0} Days" -f ($Age) +"color#" }  else { "{0} Days" -f ($Age) } }},
    @{n="Snapshot Name";e={$_.Name}}

#Nothing found? Show it as such
If (-not $Report)
{  $Report = New-Object PSObject -Property @{
    Hostname = "No snapshots found on any VM's controlled by $VIServer"
    Size = ""
    Age = ""
    "Snapshot Name" = ""
   }
}

#Loop through VMs and find the Notes
foreach ($VM in $Report) {
    $Notes = $VM.Hostname | Select -ExpandProperty Notes
    $VM | Add-Member -MemberType NoteProperty -Name Notes -Value $Notes
    $VMHost = $VM.Hostname | Select -ExpandProperty VMHost
    $VM | Add-Member -MemberType NoteProperty -Name VMHost -Value $VMHost.toString().subString(0,2).toUpper()
}

#Convert results to an HTML report
$Report = $Report | Select Hostname, Size, Age, "Snapshot Name", Notes, @{n="Location";e={$_.VMHost}} | 
    ConvertTo-Html -Head $style -PreContent $PreContent

    
$Report = $Report -replace "#color","<font color='red'><b>"
$Report = $Report -replace "color#","</b></font>"
$Report | Out-File c:\VMReport.html 

#Log the date that the task was run
LogMsg "Report generated on $Date"

}
#Catch any errors, write to log
Catch
{
logMsg "

$($Error[0].ToString())

"
}
}

#Region Main
LogMsg "------------------------ START ------------------------"
$script:StartTime = get-date
#Check if required module is installed. If found, no need to reinstall.
if (-not (Get-Module -ListAvailable -name VMWare.PowerCLI)) {
    Try { 
    Install-Module -Name VMWare.PowerCLI -ErrorAction Stop
    LogMsg "Installed VMWare.PowerCLI Module"
    }
    Catch { Write-Host "Unable to load PowerCLI, is it installed?" -ForegroundColor Red; Break }
}
SnapshotEmail
LogMsg "Exit Code: $ExitCode"
LogMsg "------------------------ Finish ------------------------"