Shutdown-ESXHosts
========

Automate shutting down of all VMs on an ESX host, setting maintenance mode, and shutting down the Host itself

## Includes:
- Logging to location $global:sLogDir
- Shuts down all VM's, waits upto 200 seconds (configurable) and keeps trying
- Puts host in maintenance mode
- Shuts down ESX host
- Error handling

## Requirements
- PowerShell 5.0
- ESX 5.1+
- PowerCLI module (https://www.vmware.com/support/developer/PowerCLI/)

## Instructions
- Replace variables (server names, log location, etc)






