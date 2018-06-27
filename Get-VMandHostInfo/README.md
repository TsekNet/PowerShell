Get-VMandHostInfo
========

## Gathers VM Information for all VMs on a ESXi host:
- RAM
- CPU
- HDD
- ESXi Host VM belongs to

## Gathers ESXi Host information:
- RAM (Perecent Used / Amount used / Amount Total)
- CPU (Percent Used / Count)

## Gathers ESXi datastore information:
- Datastore % used
- Amount Used
- Capacity

## Requirements
- PowerShell 3.0+
- Account that has at least read access to vCenter/vSphere infrastructure

## Usage
.\Get-VMandHostInfo.ps1 -VIServer $array -userName $user -pass $pass
