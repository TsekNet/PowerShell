 <# 
    .SYNOPSIS
     Export Security Group Membership to CSV

    .NOTES 
     NAME: Get-SecurityGroupMembers.ps1
	 VERSION: 1.0
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 2/7/2017
#>


$users = import-csv “c:\temp\grouplist.csv"
$output = ForEach ($item in $users)

{

    # I like to assign each property value to a simpler named variable, but it’s not necessary

    $Group = $item.(“Group") 

    #Uses Get-ADGroupMember function to go through all rows under the column titled "Group" in the CSV and outputs the name

    write-output $Group
    write-output "--------"
    <#
    write-output $(Get-ADGroupMember -Identity $Group | 
    Where-Object { $_.objectClass -eq 'group' }) |
    select name

    Get-ADGroupMember -Identity $Group | 
    Where-Object { $_.objectClass -eq 'user' } | 
    Get-ADUser -Properties employeeID | 
    select name,employeeID | ConvertTo-Csv -NoTypeInformation | 
    % { $_ -replace '"', ""}    
    #>


    $results = Get-ADGroupMember -Identity $Group  | select name,employeeID,objectClass,samaccountname

    foreach ($result in $results){
    if ($result.objectClass -like 'group'){
    Write-Output $result.name
    }
    elseif ($result.objectClass -eq 'user'){
    $aduser = Get-ADUser -Identity $result.samaccountname -Properties employeeID
    Write-Output "$($result.name), $($aduser.employeeID)"
    }
    }
        Write-Output ""
        

    


} $output | out-file "C:\temp\Groupmembers.csv" -Append -fo -en ascii 

<#
$ACL_NAME = "ACL_PM_RO"
$in_file = "C:\Temp\secgroups\input\$ACL_NAME.csv"
$out_file = "C:\Temp\secgroups\output\$ACL_NAME-output.csv"

$out_data = @()

ForEach ($row in (Import-Csv $in_file)) {
    $user = $row.'user name'
        $out_data += Get-ADGroup -Filter "Name -eq '$user'" | select Name
        $out_data += Get-ADUser -Filter "Name -eq '$user'" -Properties employeeID | select Name,employeeID
        
} 

$out_data | convertto-csv -NoTypeInformation # | % { $_ -replace '"' } | out-file $out_file -fo -en ascii
#>