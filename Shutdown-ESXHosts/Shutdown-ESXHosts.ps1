<# 
    .SYNOPSIS
     Automate shutting down of all VMs on an ESX host, setting maintenance mode, and shutting down the Host itself

    .NOTES 
     NAME: Shutdown-ESXHosts.ps1
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 8/25/17
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
	
    $global:sLogDir = "C:\Windows\System32\~FDS\Logs\$($ScriptName)_$Year-$Month-$Day.log"
	
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
   Remove-Item C:\Windows\System32\~FDS\Logs\$($ScriptName)* -Exclude *_$Year-$Month-*.log
}

function Shutdown-ESXHosts {

Disconnect-VIServer * -Confirm:$false

#Define static variables
$VIServer = "esxiserver.domainname.com"

$User = "DOMAIN\Username"
$PW = "Password"

#Connect to vCenter server
Connect-VIServer $VIServer -User $User -Password $PW | Out-Null
 
# Get All the ESX Hosts
$ESXSRV = Get-VMHost
LogMsg "$ESXSRV server found"
 
# For each of the VMs on the ESX hosts
Foreach ($VM in ($ESXSRV | Get-VM)){
    # Shutdown the guest cleanly
    LogMsg "$VM - virtual machine found"
    $VM | Shutdown-VMGuest -Confirm:$false
}
 
# Set the amount of time to wait before assuming the remaining powered on guests are stuck
$waittime = 200 #Seconds
 
#What time is it
$Time = (Get-Date).TimeofDay
do {
    # Wait for the VMs to be Shutdown cleanly
    sleep 1.0
    $timeleft = $waittime - ($Newtime.seconds)
    $numvms = ($ESXSRV | Get-VM | Where { $_.PowerState -eq "poweredOn" }).Count
    LogMsg "Waiting for shutdown of $numvms VMs or until $timeleft seconds"
    $Newtime = (Get-Date).TimeofDay - $Time
    } until ((@($ESXSRV | Get-VM | Where { $_.PowerState -eq "poweredOn" }).Count) -eq 0 -or ($Newtime).Seconds -ge $waittime)

# Set maintenance mode
Sleep 15
Set-VMhost -VMhost $ESXSRV -State Maintenance
LogMsg "Setting maintenance mode for server $ESXSRV"

# Shutdown the ESX Hosts
Sleep 15
$ESXSRV | Foreach {Get-View $_.ID} | Foreach {$_.ShutdownHost_Task($TRUE)}
 
LogMsg "Shutdown of server $ESXSRV Complete"

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
Shutdown-ESXHosts
LogMsg "Exit Code: $ExitCode"
LogMsg "------------------------ Finish ------------------------"