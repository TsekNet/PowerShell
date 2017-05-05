 <# 
    .SYNOPSIS
     Finding service accounts with old passwords

    .NOTES 
     NAME: Get-EmployeeIDFromUser.ps1
	 VERSION: 1.0
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 7/6/2015
#>

Import-Module ActiveDirectory

Function Main
{
    Write-Host "### Finding service accounts with old passwords ###"
    $Users = Get-ADUser -Filter {PasswordNeverExpires -eq $True} -Properties SamAccountName,PasswordLastSet
    $Today = Get-Date

    $OldPassword = @()

    foreach ( $user in $users )
    {
       $TimeSpan = New-TimeSpan -Start ($user.PasswordLastSet) -End $Today

        $obj = New-Object System.Object
        $obj | Add-Member -type NoteProperty -Name 'SamAccountName' -Value $User.SamAccountName 
        $obj | Add-Member -type NoteProperty -Name 'Password Age' -Value $TimeSpan.Days

        if ( $TimeSpan.Days -gt 90 )
        {
            $OldPassword += $obj
        }
    }

    Write-Host " Accounts with old passwords:"
    Write-Host ""
    $OldPassword
}

Main