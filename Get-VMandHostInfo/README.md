Get-VMandHostInfo
========

## Gathers VM Information for all VMs on a ESXi host:
- RAM
- CPU
- HDD
- ESXi Host VM belongs to
- Outputs to c:\temp\vms.html file

## Gathers ESXi Host information:
- RAM (Perecent Used / Amount used / Amount Total)
- CPU (Percent Used / Count)
- Outputs to c:\temp\hosts.html file

## Gathers ESXi datastore information:
- Datastore % used
- Amount Used
- Capacity
- Outputs to c:\temp\hosts.html file

## Requirements
- PowerShell 3.0+
- Account that has at least read access to vCenter/vSphere infrastructure

## Usage
.\Get-VMandHostInfo.ps1 -VIServer $array -userName $user -pass $pass
