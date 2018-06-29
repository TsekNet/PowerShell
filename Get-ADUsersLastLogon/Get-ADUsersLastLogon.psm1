<#
.Synopsis
   Find User last logon time accross all domain controllers
.DESCRIPTION
   Uses last logon time ad user attribute to find the last time authenticated. 
   Only concerned with users in the last 7 days.
.EXAMPLE
   Get-ADUsersLastLogon -OU 'OU=User Groups,DC=example,DC=local' -Activity 7
#>

Import-Module ActiveDirectory

function Get-ADUsersLastLogon {
    [CmdletBinding(SupportsShouldProcess=$true,
                   HelpUri = 'https://www.tseknet.com')]
    Param (
     [Parameter(ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
     $OU = 'OU=User Groups,DC=example,DC=local',
     [int]$Activity = 7,
     [string]$OutFile = 'c:\temp\lastLogon.csv'
    )

    # Take the current date and subtract the amount of days noted above to find the relevant users below
    $Date = Get-Date
    $Week = $Date.AddDays(-$Activity)

    # Find all active users that have2
    $Users = Get-ADUser -SearchBase $OU -Filter {Enabled -eq $true -and lastLogon -ge $Week} -Properties samAccountName, Name, lastLogon
    $DomainControllers = Get-ADDomainController -Filter * | select hostname

    foreach ($User in $Users) {
        foreach ($DC in $DomainControllers) {
            # Create a new object with the current domain controller and current user info
            $obj = New-Object PSOBject -Property @{
                DC = $DC.hostname
                User = $User.Name
                LastSeen = $User.lastLogon}
             
            # If the current user lastLogon time is less than the previous user, use that info instead
            if ($obj.LastSeen -lt $User.LastLogon){
                $time = $User.LastLogon
                } else {
                
                #Otherwise, just keep the same lastLogon time, as it was greater than or equal to the current value 
                $time = $obj.LastSeen
                }
        }
    }

        # Export everything to CSV, reformat lastLogon from UnixTime to readable format
        $Users | select samAccountName, Name, @{n='LastSeen';e={[datetime]::FromFileTime($_.lastLogon).ToShortDateString()}} |
        Sort-Object LastSeen -Descending | ConvertTo-Csv -Delimiter " " -NoTypeInformation |  Out-File $outfile

}

Get-ADUsersLastLogon