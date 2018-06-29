# Get-ADUsersLastLogon
Find User last logon time accross all domain controllers

## Parameters:
- $OU = Organizational Unit (Full Distinguished Name)
- [int]$Activity = After how many days is a user considered inactive?
- [string]$OutFile = Exports CSV file with all user info

## Usage
Get-ADUsersLastLogon -OU 'OU=User Groups,DC=example,DC=local' -Activity 7 -OutFile 'c:\temp\outfile.csv'

## Requirements
- PowerShell 3.0+
- Read Access to AD
- RSAT
