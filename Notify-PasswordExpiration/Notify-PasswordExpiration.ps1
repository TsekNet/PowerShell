<# 
    .SYNOPSIS
     Send emails to users whose passwords are expiring soon. See $OU and $DC variables to customize effected users.

     Requires RSAT to be installed on system executing this script

    .NOTES 
     NAME: Notify-PasswordExpiration
	 VERSION: 1.3
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 5/2/17
#>
param([string]$WorkingDir= (Get-Location).ProviderPath)

#region Global Variables
$Script:ProgramVersion = "1.3"
$Script:ExitCode = "0"
$Script:TimeStamp = Get-Date -Format yyyy-MM-dd_HH-mm-ss


#end region

#region Functions
Function PasswordCheck{
PasswordCheckandEmail
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
Function PasswordCheckandEmail {
    #Notify when 15 days left
    $notifyDays = 45
    $Date = (Get-Date).AddDays(-$notifyDays)

    #Notify when expired. Add one day to not include today's date when calculating expirations
    $expiredDays = 61
    $Expired = (Get-Date).AddDays(-$expiredDays)

    #Assume user is inactive after 4 months of not logging in
    $numberActive = 119
    $lastLogon = (Get-Date).AddDays(-$numberActive)

    #Domain Controller and OU
    $dc = "DC"
    $OU = "OU"

    #Query COMPANY AD for users based on specs above
    $Users = Get-ADUser -server $dc -SearchBase $OU -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $false -and PasswordNotRequired -eq $false -and PasswordLastSet -le $Date -and lastLogon -ge $lastLogon} -Properties mail,PasswordLastSet,PasswordNeverExpires,PasswordNotRequired,displayName

    #Loop through all users from query above
    foreach ($User in $Users) {
    $fName = $User.displayName
    $userName = $User.samAccountName.ToLower()
    $email = $User.mail.ToLower()
    $lastSet = $User.PasswordLastSet

    #Used to calculate days until password is expiring. 
    $timeLeft = ($lastSet - $Expired).Days

    ################################## BEGIN EMAIL ##################################

    #Different email subject line based on situation
    $messageSubjectExpiring = "Your OTHERCOMPANY password is expiring in $timeLeft days!"
    $messageSubjectExpired = "Your OTHERCOMPANY password has expired, $fname!"

    #smtp attributes, called in if statements below
    $smtpTo = "$fname <$email>"
    $smtpFrom = "OTHERCOMPANY Support <sUPPORT@OTHERCOMPANY.com>"
    $smtpServer = "mailhost.OTHERCOMPANY.com"
    $messagebody = "
    <style>
        th {
        background-color: #3496DB;
        color: white;
        }

        table, th, td {
        border: 1px solid black;
        border-collapse: collapse;
        padding: 3px;
        font-size: 13px;
        font-family: verdana;
        }
    </style>
    <font face='verdana' size='2'>
    <p>Hi $fName,</p>
    "
    
    #Help Section - Mainly to give contact info
    $helpSection = "    
    <p><h3>------------------------------Need Help?------------------------------</h3></p>
    <p>We have engineers located all over the world that monitor this system 24 hours a day 7 days a week.<p>
    <p>You can ring direct to our Operations Staff using the in country numbers below:</p>

    <p><table>
        <tbody>
		OTHERCOMPANY contact info
        </tbody>
        </table>
        </p>
    </font> 
    "

    #User has 14 days until their password expires
    if ($timeLeft -eq 14){
    LogMsg "$fName ($email) expiring in $timeLeft days"
    $messagebody += "
    <p><b>You are required to change the password for your OTHERCOMPANY account every 60 days.</b></p>
    <p>Passwords must be a minimum of eight characters and contain three of the following four categories: upper case alpha, lower case alpha, numbers, and symbols.</p>
    <p>OTHERCOMPANY Username: <b>$userName</b></p>
    <p><h3>---------------OTHERCOMPANY Password Reset Instructions---------------</h3>
    <p>If you do not have a OTHERCOMPANY domain computer, your OTHERCOMPANY password can only be updated via <b>webmail.OTHERCOMPANY.com</b> prior to expiration.</p>
    <p>To do this, please follow the steps below:</p>
    <ol>
    <li>Navigate to <b><a href=webmail.OTHERCOMPANY.com>webmail.OTHERCOMPANY.com</a></b> in your web browser of choice</li>
    <li>Log in using the username <b>$userName</b> and your current OTHERCOMPANY password</li>
    <li>Select <b>Options</b> at the top right of the page</li>
    <li>From the menu, select <b>Change Your Password...</b> </li>
    <li>Type the current password in the <b>Current Password</b></li>
    <li>Enter your new password in both the <b>New Password</b> and <b>Confirm New Password</b> fields.
    <li>Close your browser window and reopen webmail.OTHERCOMPANY.com.  You should now be able to log in using your new password.</li>
    </ol>
    "

    $messagebody += $helpSection

    Send-MailMessage -To $smtpTo -From $smtpFrom -Subject $messageSubjectExpiring -Body $messagebody -BodyAsHtml -SmtpServer $smtpServer 
    }

    #User password has expired today
    elseif ($timeLeft -eq 0){ 
    LogMsg "$fName ($email) Password has expired."
    $messagebody += "
    <b><p style=color:red;>Your OTHERCOMPANY credentials have expired.</b></p>
    <p>These credentials are used to log into OTHERCOMPANY services such as webmail.OTHERCOMPANY.com and vpn.OTHERCOMPANY.com.</p>
    <p>Please dial <b>+1 855 225 2255 and request your password be reset to regain access to these services. For support internationally, please see list of support numbers at the bottom of this email.</p>

    <p>OTHERCOMPANY Username: <b>$userName</b>

    <p>Once you receive your new password, make sure to set it to something more secure, using the instructions below:</p>

    <p><h3>---------------OTHERCOMPANY Password Reset Instructions---------------</h3>
    <p>If you do not have a OTHERCOMPANY domain computer, your OTHERCOMPANY password can only be updated via <b><a href=webmail.OTHERCOMPANY.com>webmail.OTHERCOMPANY.com</a></b> prior to expiration.</p>
    <p>To do this, please follow the steps below:</p>
    <ol>
    <li>Navigate to <b><a href=webmail.OTHERCOMPANY.com>webmail.OTHERCOMPANY.com</a></b> in your web browser of choice</li>
    <li>Log in using the username <b>$userName</b> and your current OTHERCOMPANY password</li>
    <li>Select <b>Options</b> at the top right of the page</li>
    <li>From the menu, select <b>Change Your Password...</b> </li>
    <li>Type the current password in the <b>Current Password</b></li>
    <li>Enter your new password in both the <b>New Password</b> and <b>Confirm New Password</b> fields.
    <li>Close your browser window and reopen webmail.OTHERCOMPANY.com.  You should now be able to log in using your new password.</li>
    </ol>
    "

    $messagebody += $helpSection

    Send-MailMessage -To $smtpTo -From $smtpFrom -Subject $messageSubjectExpired -Body $messagebody -BodyAsHtml -SmtpServer $smtpServer 
    }

    ################################## END EMAIL ##################################


    }
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
					$arg = "-ExecutionPolicy Unrestricted -file $($MyInvocation.ScriptName) -server $server -workingDir $WorkingDir" 
				}
				Else
				{
					$arg = "-ExecutionPolicy Unrestricted -file $($MyInvocation.ScriptName) -workingDir $WorkingDir" 
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
PasswordCheck
LogMsg "Exit Code: $ExitCode"
LogMsg "------------------------ Finish ------------------------"

$script:FinishTime = get-date
Exit ($ExitCode)
#EndRegion