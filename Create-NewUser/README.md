Create-NewUser
========

Powershell Form GUI used to Automate new hire process. 

## Includes:
- Creating user account based on copied user.
- Sending automated HTML new hire welcome email
- Creating file server share
- Data validation
- Data output and confirmation
- Error handling
- Real Time Progressbar

## Requirements
- RSAT to be installed on system executing this script
- Two active directory domains 
- Delegated permissions to create users in active directory
- PowerShell 5.0

## Instructions
- Replace variables with your domain names and OU formats
- Run using right click -> run as different user from the shortcut provided.
  - This user should have delegated access to both active directory structures

