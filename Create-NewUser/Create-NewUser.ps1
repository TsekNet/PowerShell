 <# 
    .SYNOPSIS
     Automate new hire process using PowerShell GUI!
	 
	 Includes:

     Creating user account based on copied user.
     Sending new hire welcome email (cc hr)
     Creating file server share

     Requires RSAT to be installed on system executing this script

    .NOTES 
     NAME: Create-NewUser.ps1
	 VERSION: 0.6
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 1/11/17
#>

#Required for creating account
import-module activedirectory

#Text entered variables
$w=$firstNameText.Text
$x=$lastNameText.Text
$y=$phoneText.Text
$z=$copyUserText.Text

#Clear any entered values between loops
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue

#Loop until the user hits cancel, there is an error, or the PIN is set
Do
{

#Continue until there is an error
Try
{
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.TextBox")

################################### BEGIN FORM FORMATTING ###################################

#Container size, position, and title
$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "New User Setup"
$objForm.Size = New-Object System.Drawing.Size(245,485) 
$objForm.StartPosition = "CenterScreen"

#Form Icon
#$objform.Icon = New-Object system.drawing.icon (".\FDS.ICO")

#Disable Maximize button
$objForm.MaximizeBox = $false
$objForm.FormBorderStyle = 'FixedSingle'

#Enter and Esc actions
$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$w;$x;$y;$z;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})
    
#OK button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(3,333)
$OKButton.Size = New-Object System.Drawing.Size(115,23)
$OKButton.Text = "Create User"
$OKButton.Add_Click({$Script:w=$firstNameText.Text;$Script:x=$lastNameText.Text;$Script:y=$phoneText.Text;$Script:z=$copyUserText.Text;$global:Clicked=$True;$objForm.Close()})
$objForm.Controls.Add($OKButton)
$objForm.AcceptButton = $OKButton
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

#Cancel Button
$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(120,333)
$CancelButton.Size = New-Object System.Drawing.Size(115,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

#Font Type/size/etc
$FontBold = new-object System.Drawing.Font("Arial",8)

#Main message
$mainMsgLabel = New-Object System.Windows.Forms.Label
$mainMsgLabel.Location = New-Object System.Drawing.Size(5,12) 
$mainMsgLabel.Size = New-Object System.Drawing.Size(245,70)
$mainMsgLabel.Font = $fontBold
$mainMsgLabel.text = "<Company> New Hire Script
- Creates user account based on copied user
- Creates Personal File Share
- Sends email to new hire with starter info"
$objForm.Controls.Add($mainMsgLabel)

#Copy User
$copyUserLabel = New-Object System.Windows.Forms.Label
$copyUserLabel.Location = New-Object System.Drawing.Size(10,103) 
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

#Extension Text
$extLabel = New-Object System.Windows.Forms.Label
$extLabel.Location = New-Object System.Drawing.Size(10,178) 
$extLabel.Size = New-Object System.Drawing.Size(65,20)
$extLabel.Text = "Extension:"
$objForm.Controls.Add($extLabel)
$extLabel = New-Object System.Windows.Forms.Label
$extLabel.Location = New-Object System.Drawing.Size(182,178) 
$extLabel.Size = New-Object System.Drawing.Size(65,20)
$extLabel.Text = "(4 digits)"
$objForm.Controls.Add($extLabel)

#Job Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Size(10,202) 
$titleLabel.Size = New-Object System.Drawing.Size(65,20)
$titleLabel.Text = "Job Title:"
$objForm.Controls.Add($titleLabel)

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
$emplIDLabel.Text = "EmplID:"
$objForm.Controls.Add($emplIDLabel)
$emplIDLabel = New-Object System.Windows.Forms.Label
$emplIDLabel.Location = New-Object System.Drawing.Size(182,250) 
$emplIDLabel.Size = New-Object System.Drawing.Size(65,20)
$emplIDLabel.Text = "(5 digits)"
$objForm.Controls.Add($emplIDLabel)

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

#Phone Number
$phoneText = New-Object System.Windows.Forms.TextBox
$phoneText.Location = New-Object System.Drawing.Size(80,175)
$phoneText.Size = New-Object System.Drawing.Size(35,20) 
$phoneText.MaxLength = 4
$objForm.Controls.Add($phoneText)

#Job Title
$titletext = New-Object System.Windows.Forms.TextBox
$titletext.Location = New-Object System.Drawing.Size(80,200)
$titletext.Size = New-Object System.Drawing.Size(150,20) 
$objForm.Controls.Add($titletext)

#Office
$officeDropDown = New-Object System.Windows.Forms.ComboBox
$officeDropDown.Location = New-Object System.Drawing.Size(80,225) 
$officeDropDown.Size = New-Object System.Drawing.Size(35,20) 
$officeDropDown.DropDownHeight = 200 
$objForm.Controls.Add($officeDropDown) 
$wksList=@("NY","IN","UK","HK")
foreach ($wks in $wksList) {
                      $officeDropDown.Items.Add($wks)
                              }

$emplIDText = New-Object System.Windows.Forms.TextBox
$emplIDText.Location = New-Object System.Drawing.Size(80,250)
$emplIDText.Size = New-Object System.Drawing.Size(40,20) 
$emplIDText.MaxLength = 5
$objForm.Controls.Add($emplIDText)

################################### END FORM FORMATTING ###################################

#Disable OK Button by default. Enable when there is text in textbox's
$OKButton.Enabled = $false
$copyUserText.add_TextChanged{ Checkfortext }
$firstNameText.add_TextChanged{ Checkfortext }
$lastNameText.add_TextChanged{ Checkfortext }

function Checkfortext
{ 
	if ($firstNameText.Text.Length -and $lastNameText.Text.Length -and $copyUserText.Text.Length) 
	    {
		    $OKButton.Enabled = $True
	    }
}

$objForm.Topmost = $True
$handler = {$objForm.ActiveControl = $firstNameText}

$objForm.add_Load($handler)
$objForm.Add_Shown({$objForm.Activate();$copyUserText.focus()})
[Void] $objForm.ShowDialog()

#If the first name value entered is not empty, null
if ($OKButton.Enabled.Equals($true)) {

    #Set variables
    $Username = ($w.Substring(0,1)+$x).ToLower()
    $phone = "1-212-370-"+$y
    $name = Get-AdUser -Identity $z -Properties *
    $global:copyUserName = $name.SamAccountName
    $DN = $name.distinguishedName
    $OldUser = [ADSI]"LDAP://$DN"
    $Parent = $OldUser.Parent
    $OU = [ADSI]$Parent
    $OUDN = $OU.distinguishedName
    $fname = (Get-Culture).TextInfo.ToTitleCase($w)
    $lname = (Get-Culture).TextInfo.ToTitleCase($x)
    $flname = $fname +" "+ $lname
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 
    $email = $Username +"@"+ $domain
    $office = $officeDropDown.SelectedItem
    $desc = (Get-Culture).TextInfo.ToTitleCase($titletext.Text)
    $tQuery = Get-ADUser -Identity $copyUserName
    $tUser = $tQuery.name
    $findGID = Get-ADGroup -Identity "Domain Users" -Properties *
    $gidNumber = $findGID.gidNumber
    $emplID = $emplIDText.Text

    #Confirm information input into form
   $OUTPUT = [System.Windows.Forms.MessageBox]::Show(
"   Template user '$tUser' exists
    First Name: $fname
    Last Name: $lname
    Username: $Username
    Email: $Username@<Company>.com
    Phone Number: $phone
    Job Title: $desc 
    Office: $office
    Employee ID: $emplID
    
    

    Is all the information above correct?", "Confirm Entered Information", "YesNo", "Information")

        if ($OUTPUT -eq "YES") {

            #Create user account based on copy user, and input values
            New-ADUser -SamAccountName $Username -Name $flname -GivenName $fname -Surname $lname -Instance $DN -Path "$OUDN" `
            -AccountPassword (ConvertTo-SecureString -AsPlainText "Pass" -Force) –userPrincipalName $email `
            -Description $desc -Office $office -DisplayName $flname -OfficePhone $phone `
            -Enabled $true -EmailAddress $email -EmployeeID $emplID

            Set-ADUser -Identity $Username -replace @{unixHomeDirectory=$Username; loginshell="/bin/bash"; uid=$Username; gidNumber=$gidNumber} 

            $groups = (GET-ADUSER –Identity $name –Properties MemberOf).MemberOf
            foreach ($group in $groups) { 

            Add-ADGroupMember -Identity $group -Members $Username

            #Fileserver path for user share creation
            $fileserver = "\\Path\to\file\server"
            
            #Create User Personal Share on file server
            New-item -ItemType Directory -Path $fileserver\$Username
            $acl = Get-Acl $fileserver\$Username
            $acl | Format-List
            $acl.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
            $acl.SetAccessRuleProtection($true, $true)
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $email,"Modify, Synchronize", "ContainerInherit, ObjectInherit", "None", "Allow"
            $acl.addAccessRule($rule)
            Set-Acl $fileserver\$Username $acl

################################## BEGIN EMAIL ##################################

#Email Variables
$messageSubject = "Welcome to <Company>, a <Other Company> Company - $flname!"
$smtpTo = "$fname $lname <$email>"
$smtpCC = @("email@company.com", "email@company2.com")
$smtpFrom = "support@company.com"
$smtpServer = "mailhost.company.com"

$messagebody = 

"
<font face='verdana' size='2'>
<p>Below you will find information regarding your phone and computer setup.</p>
<p>--------------------------------<br />
<Company>
<br />--------------------------------<br />
<Company> Username: <strong>$Username</strong><br />
<Company> Email:<strong> $email</strong><br />
<Company> Extension:<strong> $y</strong></p>
<p>--------------------------------<br />
<Other Company>
<br />--------------------------------<br />
<Other Company> Username: <strong><Other Domain>\$Username</strong>
<br /><Other Company> Email: <strong>$fname.$lname@<Other Company>.com</strong></p>
<p>You are required to change the password for both accounts every 60 days. Passwords must be a minimum of eight characters and contain three of the following four categories: upper case alpha, lower case alpha, numbers, and symbols.</p>
<p>--------------------------------<br />
Phone Information
<br />--------------------------------<br />
External callers can reach you at <strong>$phone</strong>. Your voicemail password is the same as your extension (<strong>$y</strong>). Please log in to your voicemail and change your voicemail password at your earliest convenience. Instructions for using your office telephone, including how to setup and check your voicemail, can be found here.</p>
<p>--------------------------------<br />
Personal Folder
<br />--------------------------------<br />
A personal folder has been created for you, located at H:\. Any file or folder in your H:\ drive will be included in our daily backup. No file stored on your computer will be backed up, so be sure all important files and documents are stored safely on your H:\ drive.</p>
<p>--------------------------------<br />
Technical Assistance
<br />--------------------------------<br />
For support on computer and phone related issues please contact <Company> Support by email at support@<Company>.com, by phone using ext. <b>8398</b> internally, or <b>1-212-370-8398</b> from outside the office. <br />
<Company>'s Support team consists of Matt Burtless, Dan Tsekhanskiy, Deepak Sreedharan, and Dinesh Vegesina.<br /><br />
If you need additional services, such as remote access or a conferencing account please contact Support for more information.</p>
<p>Thank you, and, again, welcome to <Company>, a <Other Company> Company!</p>
<p>- <Company> Support</p>
</font>"

################################## END EMAIL ##################################

}

Send-MailMessage -To $smtpTo -From $smtpFrom -Cc $smtpCC -Subject $messagesubject -Body $messagebody -BodyAsHtml -SmtpServer $smtpServer
}

}

#Anything else
else { exit }

}

Catch
{
[System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Please forward this error to your System Administrator") 
}

}
#Keep looping if user selects "No" on a incorrect` entry
while ($OUTPUT -eq "No")