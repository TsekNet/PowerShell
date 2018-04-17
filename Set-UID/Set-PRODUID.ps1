 <# 
    .SYNOPSIS
     Set Posix attributes (uid, gid, etc) for other domains based on Main domain

    .NOTES 
     NAME: Set-UID.ps1
	 VERSION: 1.4
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 4/20/17

#>

param([string]$WorkingDir= (Get-Location).ProviderPath)

#region Global Variables
$Script:ProgramVersion = "1.4"
$Script:ExitCode = "0"
$Script:TimeStamp = Get-Date -Format yyyy-MM-dd_HH-mm-ss
#end region

Function Update{
UpdateAttributes
}
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
	
	#Write-Host "ScriptName: $ScriptName"
	
    Out-File -FilePath "C:\Windows\System32\~Logs\$($ScriptName)_$Year-$Month-$Day.log" -InputObject "$CurDate $sLogText" -Append
	#Out-File -FilePath "C:\Test\$($ScriptName)_$Year-$Month-$Day.log" -InputObject "$CurDate $sLogText" -Append
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
   Remove-Item C:\Windows\System32\~Logs\$($ScriptName)* -Exclude *_$Year-$Month-*.log
}

function UpdateAttributes {
$destou = "DN"
$dc = "DC"
$account = "Production Service Account"
#$cred = Get-Credential -UserName $account -Message "$dc login"
$i=0
$x=0

#Use this guide to create powershell secure password file https://www.pdq.com/blog/secure-password-with-powershell-encrypting-credentials-part-1/
$File = "Path to secure password file"
$MyCredential=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $account, (Get-Content $File | ConvertTo-SecureString)
 
Import-Module ActiveDirectory
 
#Define users to process (all users in $destou who are enabled and have an empty uid)
LogMsg "Collecting user information..."
 
$ADUsers = Get-ADUser -Server $dc -SearchBase $destou -Filter {enabled -eq "true"} -Credential $MyCredential -Properties sAMAccountName, DistinguishedName, gidNumber, uid, uidnumber, unixHomeDirectory, loginShell

#Loop through all $UATUsers
$ADUsers | ForEach-Object {
    
    #Query CORP domain for only users that also exist in $destou
    $CORPUsers = Get-ADUser -Filter { SamAccountName -eq $_.SamAccountName } `
    -Properties sAMAccountName, DistinguishedName, gidNumber, uid, uidnumber, unixHomeDirectory, loginShell

    #Set Variables for AD Attributes
    $ADsam = $ADUsers[$i].SamAccountName
    $CORPsam = $CORPUsers.SamAccountName
    $CORPuid = $CORPUsers.uid
    $CORPuidNumber = $CORPUsers.uidNumber
    $CORPgidNumber = $CORPUsers.gidNumber
    $CORPunixHomeDirectory = $CORPUsers.unixHomeDirectory
    $CORPloginShell = $CORPUsers.loginShell

    $CORPuidNumber

    #Set attributes only if the user has a $CORPuid and the account exists in both $destou and current domain's AD    
    if ($CORPuidNumber) {

    Set-ADUser -Identity $CORPsam -Server $dc -Credential $MyCredential `
    -Replace @{uidNumber=$CORPuidNumber;uid=$CORPsam;gidNumber=$CORPgidNumber;unixHomeDirectory=$CORPunixHomeDirectory;loginShell=$CORPloginShell}

    #Log to c:\windows\system32\~logs
    LogMsg "Updated user $CORPsam on $dc with the following"
    LogMsg "UID: $CORPuid | UID Number: $CORPuidNumber | GID: $CORPgidNumber | Home Dir: $CORPunixHomeDirectory | Login Shell: $CORPloginShell"
    LogMsg

    #Updated user count
    $x++

    }    
    
    #Increment number in looped array
    $i++

}

#Log total users
LogMsg
LogMsg "$x users updated!"

}

Function Use-RunAs{    
  
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")    
	#Return $IsAdmin
 
    If ($MyInvocation.ScriptName -ne "") 
    {  
        if (!$IsAdmin)  
        {  
            Try 
            {  
				If ($server)
				{
					$arg = "-ExecutionPolicy Unrestricted -file `"$($MyInvocation.ScriptName)`" -server $server -workingDir $WorkingDir" 
				}
				Else
				{
					$arg = "-ExecutionPolicy Unrestricted -file `"$($MyInvocation.ScriptName)`" -workingDir $WorkingDir" 
				}
				
                Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
            } 
            Catch 
            { 
                Throw New-Object System.Exception("The script failed to restart as Administrator.")  
                Break               
            } 
            #Exit this session of PowerShell
			Exit
        }
    }  
    Else  
    {  
        Throw New-Object System.Exception("Error - Script must be saved as a .ps1 file first")
        Break  
    }  
} 

#Region Main
Use-RunAs
LogMsg "------------------------ START ------------------------"
$script:StartTime = get-date
Import-Module ActiveDirectory
UpdateAttributes
LogMsg "Exit Code: $ExitCode"
LogMsg "------------------------ Finish ------------------------"

$script:FinishTime = get-date
Exit ($ExitCode)
#EndRegion