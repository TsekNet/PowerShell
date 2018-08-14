# Copy-Acl
- Copys the ACL from one folder to other folder(s)
- Uses Get-Acl and Set-Acl PowerShell cmdlets to completely strip the ACL from the destination folder, then copy the ACL from the source folder)

## Parameters:
- [string]$SourceFolder = The folder that you want the permissions copied from 
- [string[]]$DestFolder = The folder(s) that you want the permissions copied to

## Usage
- Copy-Acl -SourceFolder C:\temp\Apples -DestFolder C:\Temp\Grapes -Verbose
- Copy-Acl -SourceFolder C:\temp\Apples -DestFolder C:\Temp\Grapes, C:\Temp\Oranges, C:\Temp\Strawberries -Verbose

## Requirements
- PowerShell 3.0+
- Run as administrator
