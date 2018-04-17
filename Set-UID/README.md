Set-UID
========

This script is meant to run as a scheduled task on tasksrv. It syncs unix attributes required for SSSD linux authentication accross domains. Use Set-PRODUID to copy unix attributes from Main domain to others.

## Requirements
- PowerShell 5.0

## Instructions
- Replace variables (server names, log location, etc)