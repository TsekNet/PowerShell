 <# 
    .SYNOPSIS
	
	 Powershell Form GUI used to:
     Automate new hire process. Includes:

     Creating user account based on copied user.
     Sending new hire welcome email (cc hr)
     Creating file server share
	 Real Time Progressbar

     Requires RSAT to be installed on system executing this script

    .NOTES 
     NAME: Create-NewUser.ps1
	 VERSION: 2.2
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 8/18/17
#>

param([string]$WorkingDir= (Get-Location).ProviderPath)

#region Global Variables
$Script:ProgramVersion = "2.2"
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
Function CreateNewUser {

#Text entered variables
$w=$firstNameText.Text
$x=$lastNameText.Text
$y=$phoneText.Text
$z=$copyUserText.Text

#Continue until there is an error
Try
{

#Region Import the Assemblies
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.TextBox")

################################### BEGIN FORM FORMATTING ###################################

#Container size, position, and title
$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "User Setup"
$objForm.Size = New-Object System.Drawing.Size(525,342) 
$objForm.StartPosition = "CenterScreen"

#Form Icon
$objform.Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")

#Disable Maximize button
$objForm.MaximizeBox = $false
$objForm.FormBorderStyle = 'FixedSingle'

#Always on top.
$objForm.Topmost = $True

#Enter and Esc actions
$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$w;$x;$y;$z;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})
    
#Confirm Button
$ConfirmButton = New-Object System.Windows.Forms.Button
$ConfirmButton.Location = New-Object System.Drawing.Size(3,276)
$ConfirmButton.Size = New-Object System.Drawing.Size(70,23)
$ConfirmButton.Text = "Confirm"
$objForm.AcceptButton = $ConfirmButton
$objForm.Controls.Add($ConfirmButton)

#OK button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(73,276)
$OKButton.Size = New-Object System.Drawing.Size(90,23)
$OKButton.Text = "Create User"
$objForm.Controls.Add($OKButton)

#Cancel Button
$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(163,276)
$CancelButton.Size = New-Object System.Drawing.Size(70,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

#Font Type/size/etc
$mainMsgLabelFont = new-object System.Drawing.Font("Arial",12, [System.Drawing.FontStyle]::Bold)

#Main message
$mainMsgLabel = New-Object System.Windows.Forms.Label
$mainMsgLabel.Location = New-Object System.Drawing.Size(3,3) 
$mainMsgLabel.Size = New-Object System.Drawing.Size(245,20)
$mainMsgLabel.Font = $mainMsgLabelFont
$mainMsgLabel.text = "~COMPANY1NAME~ New Hire Script"
$objForm.Controls.Add($mainMsgLabel)

#Main message Part 2
$mainMsgLabel2 = New-Object System.Windows.Forms.Label
$mainMsgLabel2.Location = New-Object System.Drawing.Size(5,25) 
$mainMsgLabel2.Size = New-Object System.Drawing.Size(245,65)
#$mainMsgLabel2.Font = $fontBold
$mainMsgLabel2.text = "- Creates user account based on 'Copy User'
- Copy User = Similar username to copy from
- Creates Personal File Share
- Sends email to new hire with starter info
- Real Time Progress"
$objForm.Controls.Add($mainMsgLabel2)

#Main message
$footerLabel = New-Object System.Windows.Forms.Label
$footerLabel.Location = New-Object System.Drawing.Size(168,255) 
$footerLabel.Size = New-Object System.Drawing.Size(75,20)
$footerLabel.text = "* = Required"
$objForm.Controls.Add($footerLabel)

#Copy User
$copyUserLabel = New-Object System.Windows.Forms.Label
$copyUserLabel.Location = New-Object System.Drawing.Size(10,100) 
$copyUserLabel.Size = New-Object System.Drawing.Size(65,20)
$copyUserLabel.Text = "Copy User:*"
$objForm.Controls.Add($copyUserLabel)

#First Name
$firstNameLabel = New-Object System.Windows.Forms.Label
$firstNameLabel.Location = New-Object System.Drawing.Size(10,128) 
$firstNameLabel.Size = New-Object System.Drawing.Size(70,20)
$firstNameLabel.Text = "First Name:*"
$objForm.Controls.Add($firstNameLabel)

#Last Name
$lastNameLabel = New-Object System.Windows.Forms.Label
$lastNameLabel.Location = New-Object System.Drawing.Size(10,154) 
$lastNameLabel.Size = New-Object System.Drawing.Size(70,20)
$lastNameLabel.Text = "Last Name:*"
$objForm.Controls.Add($lastNameLabel)

#Job Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Size(10,178)
$titleLabel.Size = New-Object System.Drawing.Size(65,20)
$titleLabel.Text = "Job Title:"
$objForm.Controls.Add($titleLabel)

#Extension Text
$phoneLabel = New-Object System.Windows.Forms.Label
$phoneLabel.Location = New-Object System.Drawing.Size(10,202) 
$phoneLabel.Size = New-Object System.Drawing.Size(65,20)
$phoneLabel.Text = "Phone:"
$objForm.Controls.Add($phoneLabel)

#Office
$officeLabel = New-Object System.Windows.Forms.Label
$officeLabel.Location = New-Object System.Drawing.Size(10,226) 
$officeLabel.Size = New-Object System.Drawing.Size(65,20)
$officeLabel.Text = "Office:"
$objForm.Controls.Add($officeLabel)

#EmplID
$emplIDLabel = New-Object System.Windows.Forms.Label
$emplIDLabel.Location = New-Object System.Drawing.Size(10,250) 
$emplIDLabel.Size = New-Object System.Drawing.Size(65,20)
$emplIDLabel.Text = "Empl ID:"
$objForm.Controls.Add($emplIDLabel)

#Output message
$OutputLabel = New-Object System.Windows.Forms.Label
$OutputLabel.Location = New-Object System.Drawing.Size(273,3) 
$OutputLabel.Size = New-Object System.Drawing.Size(245,20)
$OutputLabel.Font = $mainMsgLabelFont
$OutputLabel.text = "Confirm Information Entered:"
$objForm.Controls.Add($OutputLabel)

#Output Box
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Size(273,30)
$outputBox.size = New-Object System.Drawing.Size(230,240)
$outputBox.MultiLine = $True 
$outputBox.ReadOnly = $True
$objForm.Controls.Add($outputBox)

#Divider
$divider = New-Object System.Windows.Forms.RichTextBox
$divider.Location = New-Object System.Drawing.Size(250,5)
$divider.size = New-Object System.Drawing.Size(4,295)
$divider.ReadOnly = $True
$objForm.Controls.Add($divider)

#Progress Bar
$progBarLabel = New-Object System.Windows.Forms.Label
$progBarLabel.Location = New-Object System.Drawing.Size(273,279) 
$progBarLabel.Size = New-Object System.Drawing.Size(53,20)
$progBarLabel.Text = "Progress:"
$objForm.Controls.Add($progBarLabel)
$progBar = New-Object System.Windows.Forms.ProgressBar
$progBar.Location = New-Object System.Drawing.Size(330,277) 
$progBar.Size = New-Object System.Drawing.Size(172,20)
$progBar.Value = 0
$progBar.Style = "Continuous"
$objForm.Controls.Add($progBar)
$progBar.Value = 0
$progBar.Maximum = 100

#Copy User
$copyUserText = New-Object System.Windows.Forms.TextBox
$copyUserText.Location = New-Object System.Drawing.Size(80,100)
$copyUserText.Size = New-Object System.Drawing.Size(150,20)
$objForm.Controls.Add($copyUserText)

#First Name
$firstNameText = New-Object System.Windows.Forms.TextBox
$firstNameText.Location = New-Object System.Drawing.Size(80,125)
$firstNameText.Size = New-Object System.Drawing.Size(150,20)
$objForm.Controls.Add($firstNameText)

#Last Name
$lastNameText = New-Object System.Windows.Forms.TextBox
$lastNameText.Location = New-Object System.Drawing.Size(80,150)
$lastNameText.Size = New-Object System.Drawing.Size(150,20) 
$objForm.Controls.Add($lastNameText)

#Job Title
$titletext = New-Object System.Windows.Forms.TextBox
$titletext.Location = New-Object System.Drawing.Size(80,175)
$titletext.Size = New-Object System.Drawing.Size(150,20) 
$objForm.Controls.Add($titletext)

#Phone Number
$phoneText = New-Object Windows.Forms.MaskedTextBox
$phoneText.Location = New-Object System.Drawing.Size(80,200)
$phoneText.Size = New-Object System.Drawing.Size(83,25) 
$phoneText.Mask = '#-###-###-####' 
$objForm.Controls.Add($phoneText)

#Office
$officeDropDown = New-Object System.Windows.Forms.ComboBox
$officeDropDown.Location = New-Object System.Drawing.Size(80,225) 
$officeDropDown.Size = New-Object System.Drawing.Size(40,20) 
$officeDropDown.DropDownHeight = 200
$officeDropDown.MaxLength = 2 
$officeDropDown.DropDownStyle = "DropDownList"
$objForm.Controls.Add($officeDropDown)
$wksList=@("NY","IN","UK","HK")
foreach ($wks in $wksList) {
                      $officeDropDown.Items.Add($wks)
                      }
$officeDropDown.SelectedItem = $officeDropDown.Items[0] 

#Employee ID Text Box
$emplIDText = New-Object Windows.Forms.MaskedTextBox
$emplIDText.Location = New-Object System.Drawing.Size(80,250)
$emplIDText.Size = New-Object System.Drawing.Size(40,20)
$emplIDText.Mask = '#####' 
$objForm.Controls.Add($emplIDText)

################################### END FORM FORMATTING ###################################

$outputBox.Text = "Please enter as much information as possible to continue.

At minimum, the following fields are required:

Copy User
First Name
Last Name"

#Disable OK Button by default. Enable when there is text in textbox's
$OKButton.Enabled = $false

#Confirm button click event
$ConfirmButton_Click =
{
    #Clear Variables
    $progBar.Value = 0

    if ($firstNameText.Text.Length -and $lastNameText.Text.Length -and $copyUserText.Text.Length)
        {

        
        $outputBox.Text = "Locating User...

This may take a minute..."
        $outputBox.Refresh()

        try {

        #Set variables and do magic using the input variables
        $global:DC = "DOMAIN CONTROLLER"
        $global:Username = ($firstNameText.Text.Substring(0,1)+$lastNameText.Text).ToLower()
        $global:phone = $phoneText.Text
        $global:name = Get-AdUser -Server $DC -Identity $copyUserText.Text -Properties *
        $global:copyUserName = $name.SamAccountName
        $global:DN = $name.distinguishedName
        $global:tUser = $name.name
        $global:OldUser = [ADSI]"LDAP://$DN"
        $global:Parent = $OldUser.Parent
        $global:OU = [ADSI]$Parent
        $global:OUDN = $OU.distinguishedName
        $global:fname = (Get-Culture).TextInfo.ToTitleCase($firstNameText.Text)
        $global:lname = (Get-Culture).TextInfo.ToTitleCase($lastNameText.Text)
        $global:flname = $fname +" "+ $lname
        $global:domain = "DOMAIN NAME"
        $global:email = $Username+"@"+$domain
        $global:office = $officeDropDown.SelectedItem
        $global:desc = (Get-Culture).TextInfo.ToTitleCase($titletext.Text)
        $findGID = Get-ADGroup -Server $DC -Identity "Name of Group (e.g. domain users)" -Properties gidNumber
        $global:gidNumber = $findGID.gidNumber
        $global:emplID = $emplIDText.Text
        $global:fileShare = "\\path\to\user\file\share"

        # ~COMPANYNAME~ LDAP - used to find the users ~COMPANYNAME~ email/username
        if ($emplID) {
        $~COMPANYNAME~DC = (Get-ADDomainController)
        $~COMPANYNAME~OU = "OU DN"
        $~COMPANYNAME~User = Get-ADUser -Server $~COMPANYNAME~DC -SearchBase $~COMPANYNAME~OU -Filter 'employeeID -eq $emplID' -Properties mail
        if ($~COMPANYNAME~User) {
        $global:~COMPANYNAME~UserName = $~COMPANYNAME~User.SamAccountName
        $global:~COMPANYNAME~UPN = $~COMPANYNAME~User.userPrincipalName
        $global:~COMPANYNAME~Email = $~COMPANYNAME~User.mail
        $global:~COMPANYNAME~Confirm = "~COMPANYNAME~ User: $~COMPANYNAME~UserName ($~COMPANYNAME~Email)"
        $global:~COMPANYNAME~MSG = "
            <p>--------------------------------<br />
            ~COMPANY2NAME~
            <br />--------------------------------<br />
            ~COMPANY2NAME~ Email: <b>$~COMPANYNAME~Email</b>
            <br />~COMPANY2NAME~ Username: <b>~COMPANY2DOMAIN~\$~COMPANYNAME~UserName</b>
            </p>"
        }
        }
        else {
        $~COMPANYNAME~Confirm = "~COMPANYNAME~ Employee ID: N/A"
        $~COMPANYNAME~MSG = ""
        }
        
        #Only get extension if phone textbox has text entered
        if ($phoneText.Text.Length -eq 14) {
            $global:ext = "Office Suffix + "+$phone.Substring(10,4)
            } 
            else {
            $global:phone = "N/A"
            $global:ext = "N/A"
        }

        #Set employeeID to N/A if not entered
        if ($titletext.Text.Length -le 0) {
            $desc = "N/A"
        }
        
#Display output based on user input
$outputBox.Text =
"Template user '$tUser' exists
OU: $OUDN
First Name: $fname
Last Name: $lname
Username: $Username
Phone Number: $phone
Job Title: $desc 
Office: $office
Employee ID: $emplID
$~COMPANYNAME~Confirm
Share Location: $fileShare
"
 

        #Some progress was made, add 15%
        $progBar.Value = ($progBar.Value + 15)

        #Enable the 'Create User' button if the following 3 conditions are true
        if ($firstNameText.Text.Length -and $lastNameText.Text.Length -and $copyUserText.Text.Length) 
        {
        $OKButton.Enabled = $True
        } 

#If there is an error, show it in the outputbox
} catch {
$outputBox.Text = "Please forward this error to your system administrator:

" + $Error[0].ToString()
$progBar.Value = 0
}
}

        #Make sure the user enters the required info to continue
        else {
        $outputBox.Text = "The following information is required to continue:

Copy User
First Name
Last Name"
}
}

#When the confirm button is clicked, run the $ConfirmButton_Click event
$ConfirmButton.Add_Click($ConfirmButton_Click)

#Create User button click event
$OKButton_Click = 
{
        #Some progress was made, add 15%
        $progBar.Value = ($progBar.Value + 15)
        $outputBox.Text = "Creating User...

This may take a minute..."
$outputBox.Refresh()

        LogMsg "Starting output"

            #Create user account based on copy user, and input values
            New-ADUser -Server $DC -SamAccountName $Username -Name $flname -GivenName $fname -Surname $lname -Instance $DN -Path "$OUDN" `
            -AccountPassword (ConvertTo-SecureString -AsPlainText "DefaultUserPassword" -Force) –userPrincipalName $email `
            -Description $desc -Office $office -DisplayName $flname -OfficePhone $phone `
            -Enabled $true -EmailAddress $email -EmployeeID $emplID
            Set-ADUser -Server $DC -Identity $Username -replace @{unixHomeDirectory=$Username; loginshell="/bin/bash"; uid=$Username; gidNumber=$gidNumber}

            #Get newly created user info
            $newUser = Get-ADUser -Server $DC -Identity $Username -Properties objectSID
            $SID = $newUser.objectSID
            
        #Some progress was made, add 15%
        $progBar.Value = ($progBar.Value + 15) 
        LogMsg " User Created!

        Template user '$tUser' exists
        OU: $OUDN
        First Name: $fname
        Last Name: $lname
        Username: $Username
        Phone Number: $phone
        Job Title: $desc 
        Office: $office
        Employee ID: $emplID
        $~COMPANYNAME~Confirm
        Share Location: $fileShare  
        "
            
            $groups = (GET-ADUSER -Server $DC –Identity $copyUserName –Properties MemberOf).MemberOf

        #Some progress was made, add 15%
        $progBar.Value = ($progBar.Value + 15)
        LogMsg "User group Found!"
          
            foreach ($group in $groups) {             
            Add-ADGroupMember -Identity $group -Server $DC -Members $Username            
            }       
        
        #Some progress was made, add 15%
        $progBar.Value = ($progBar.Value + 15)        
        LogMsg "User added to group!"

        #Fileserver path for user share creation
        $fileserver = "\\path\to\user\share"
            
        #Create User Personal Share on file server
        New-item -ItemType Directory -Path $fileserver\$Username
        $acl = Get-Acl $fileserver\$Username
        $acl | Format-List
        $acl.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
        $acl.SetAccessRuleProtection($true, $true)
        $ace1 = New-Object System.Security.AccessControl.FileSystemAccessRule($SID,"Modify, Synchronize", "ContainerInherit, ObjectInherit", "None", "Allow")
        $acl.addAccessRule($ace1)
            
        #Was the ACL created successfully?
        if ($ace1.IdentityReference -eq "$email")
        {
            #Some progress was made, add 15%
            $progBar.Value = ($progBar.Value + 15)
            LogMsg "$email added to $fileShare"
            }

        if ($~COMPANYNAME~Email) {
        $ace2 = New-Object System.Security.AccessControl.FileSystemAccessRule($~COMPANYNAME~UPN,"Modify, Synchronize", "ContainerInherit, ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($ace2)
        }

                #Was the ACL created successfully?
        if ($ace2.IdentityReference -eq "$email")
        {
            #Some progress was made, add 15%
            $progBar.Value = ($progBar.Value + 15)
            LogMsg "$~COMPANYNAME~UPN added to $fileShare"
            }

        Set-Acl $fileserver\$Username $acl


################################## BEGIN EMAIL ##################################

#Email Variables
$messageSubject = "Welcome to ~COMPANY1NAME~, a ~COMPANY2NAME~ Company - $flname!"
$smtpTo = "$fname $lname <$~COMPANYNAME~Email>"
$smtpCC = @("~COMPANY1NAME~ Corporate Support <corpsupport@~COMPANY1NAME~.com>", "~COMPANY1NAME~ HR <hr@~COMPANY1NAME~.com>")
$smtpFrom = "~COMPANY1NAME~ Corporate Support <corpsupport@~COMPANY1NAME~.com>"
$smtpServer = "mailhost.~COMPANY2NAME~.com"

#For Testing (comment out above)
#$smtpTo = "$fname $lname <testemailaddress@testdomain.com>"
#$smtpCC = "$fname $lname <testemailaddress@testdomain.com>"

#Style section of email
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

#User information section of email
$messagebody += "Body Of Email"

#Help Section - Mainly to give contact info
$messagebody += "Help Secton of email"

Send-MailMessage -To $smtpTo -From $smtpFrom -Subject $messagesubject -Body $messagebody -BodyAsHtml -SmtpServer $smtpServer -Cc $smtpCC

#All done. Show 100% on progress bar.
$progBar.Value = 100
LogMsg "Email Sent!"

################################## END EMAIL ##################################

#Show user final output, what user was created and file share info
$outputBox.Text =
"Template user '$tUser' copied to $Username

Name: $flname
OU: $OUDN

Phone Number: $phone
Job Title: $desc 
Office: $office
$~COMPANYNAME~Confirm

File share created in $fileShare

Email sent to $smtpTo"

#Log User info to location set in function
LogMsg "Template user '$tUser' groups copied to '$flname' in OU '$OUDN'"
LogMsg "First Name: $fname"
LogMsg "Last Name: $lname"
LogMsg "Username: $Username"
LogMsg "Email sent to $smtpTo"
LogMsg "Phone Number: $phone"
LogMsg "Job Title: $desc"
LogMsg "Office: $office"
LogMsg "$~COMPANYNAME~Confirm"
LogMsg "File share created in $fileShare"

#Some progress was made, add 10%
$progBar.Value = 100
}

#Click event for create user button
$OKButton.Add_Click($OKButton_Click)
}

Catch
{
$outputBox.Text = "Please forward this error to your system administrator:

" + $Error[0].ToString()
$progBar.Value = 0
}

$handler = {$objForm.ActiveControl = $firstNameText}
$objForm.add_Load($handler)
$objForm.Add_Shown({$objForm.Activate();$copyUserText.focus()})
[Void] $objForm.ShowDialog()

}

#Region Main
LogMsg "------------------------ START ------------------------"
$script:StartTime = get-date
Import-Module ActiveDirectory
CreateNewUser
LogMsg "Exit Code: $ExitCode"
LogMsg "------------------------ Finish ------------------------"

$script:FinishTime = get-date
Exit ($ExitCode)
#EndRegion