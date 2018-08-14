#requires -version 3.0
#requires -runasadministrator

<#
.Synopsis
   Copys the ACL from one folder to other folder(s)
.DESCRIPTION
   Uses Get-Acl and Set-Acl PowerShell cmdlets to completely strip the acl from the destination folder, then copy the ACL from the source folder
.EXAMPLE
   Copy-Acl -SourceFolder C:\temp\Apples -DestFolder C:\Temp\Grapes -Verbose
.EXAMPLE
   Copy-Acl -SourceFolder C:\temp\Apples -DestFolder C:\Temp\Grapes, C:\Temp\Oranges, C:\Temp\Strawberries -Verbose

   This command accepts multiple pipeline input for the destfolder parameter. It will loop through each folder seperately and throw an error if there as issue with one of the folders
#>

function Copy-Acl {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   HelpMessage='The folder that you want the permissions copied from')]
        [string]$SourceFolder,
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage='The folder(s) that you want the permissions copied to')]
        [string[]]$DestFolder
    )

    #BEGIN/PROCESS/END Needed for pipeline input of variables
    Begin {}
    Process {

        try {    
            $SourceAcl = Get-ACL -Path $SourceFolder
                       
            #Loop through multiple parameters, if entered. Allows editing of multiple destination folders based on one source
            Foreach ($Folder in $DestFolder){
                
                #Exit to catch if the destination folder doesn't exist
                if ((Test-Path $Folder) -eq $true){        
                    $DestAcl = Get-Acl -Path $Folder
                    $Aces = $DestAcl.Access

                    Write-Verbose "Beginning ACL edit on $Folder"
        
                    #Count how many ACEs were purged
                    $i = 0

                    ForEach ($Ace in $Aces){
                        # Get only the file path, not the powershell psprovider full path
                        $Name = $DestAcl.Path -split "::" | select -Last 1
        
                        #Purge all access rules on the destiniation folder(s) before copying the new ones over. Increment counter for each ACE edited.
                        $i++
                        Write-Verbose "Purging ACE #$i for $name" 
                        $DestAcl.RemoveAccessRule($Ace) | Out-Null
                    }
                
                    #Copy ACLs to purged destination folders
                    Write-Verbose "Copying Acl from [$SourceFolder] to the following: [$DestFolder]"
                    Set-Acl -Path $DestFolder -AclObject $SourceAcl
                } else {
                    continue
                }     
            }        
        } Catch {
            #Catch any errors, such as folder doesn't exist and others.
            Write-Error "Unexpected error occurred while executing $((Get-PSCallStack)[0].Command) with exception: $($_.Exception.Message)"
            Write-Error "Command: `'$($_.InvocationInfo.Line.Trim())`'"
            }
    }
    End {}
} 
