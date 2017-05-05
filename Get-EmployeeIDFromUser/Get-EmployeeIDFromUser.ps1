 <# 
    .SYNOPSIS
     Get employeeid's based on samaccountname
     Used during migration, in conjunction with export of usernames's taken from other current domain

     Requires RSAT to be installed on system executing this script

    .NOTES 
     NAME: Get-EmployeeIDFromUser.ps1
	 VERSION: 1.1
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 4/25/17
#>

#Required for ad queries, RSAT requires on executing computer
import-module activedirectory

#Make sure input.csv has column titled "user name" <-- exactly like that without quotes
$users = import-csv “$Env:SystemDrive\path\to\input.csv"

#loop through each user
$output = ForEach ($user in $users)

{
    # Username is equal to the values in the csv, under the column title user name (no quotes)
    $Username = $user.(“user name") 

    #Domain controller
    $server = "DC"

     #Get user from specific OU that matches username
    $results = Get-ADUser -Server $server -identity "$Username" -Properties employeeID | select sAMAccountName,employeeID

    $name = $result.sAMAccountName.ToLower()
    $employeeID = $result.employeeID

    #loop through results, add to csv
    foreach ($result in $results){
    $name+","+$employeeID
      }

    #create csv, append to it
} $output | out-file "$Env:SystemDrive\path\to\output.csv" -Append -fo -en ascii 