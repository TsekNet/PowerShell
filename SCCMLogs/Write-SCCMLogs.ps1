<#
.SYNOPSIS
  Export SCCM OS Upgrade logs to the Event Log.
.DESCRIPTION
  Regex Parse the SCCM SMSTS.log file and dump to Event Log.
.PARAMETER LogPath
  Folder to recursively search for the LogFile.
.PARAMETER LogFile
  Location of SMSTS.log on the local system.
.PARAMETER FailureString
  The string used to determine when the OS Upgrade failed.
.PARAMETER Source
  Specifies the event log source for writing logs.
#>
[CmdletBinding()]
param (
  [System.IO.FileInfo]$LogPath = "$env:WINDIR\CCM\Logs\Smstslog",
  [System.IO.FileInfo]$LogFile = 'smsts.log',
  [string]$FailureString = 'Task sequence execution failed with error code',
  [string]$Source = 'InPlaceUpgrade'
)

# Create Log Source if necessary
if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
  try {
    New-EventLog -LogName Application -Source $Source
  }
  catch {
    throw "Failed to create log source: $_"
  }
}

$log = "$LogPath\$LogFile"

# Exit if there is no log file to write to.
if (-not (Test-Path $log)) {
  throw "Failed to locate SCCM log: $log"
}

# Strip the CMTRACE loginfo from the log file. Logs are wrapped in
# <!\[LOG\[ DATA \]LOG\]!>. All we want is the DATA. Also helps keep
# under the 32KB limit for event log messages.
try {
  $formatted_log = Get-Content $log -Raw |
    ForEach-Object { $_ -replace '<!\[LOG\[', '' } |
      ForEach-Object { $_ -replace '\]LOG\]!>(.*)', '' }
}
catch {
  throw "Failed to read log file '$log' with error $_"
}

$length = $formatted_log.Length
# Trim log to under max Event Log size.
if ($length -gt 32766) {
  $formatted_log = $formatted_log[($length - 32766)..$length] -join ''
}

# Change log level and prepend custom success/failure string.
if ($formatted_log -match $FailureString) {
  $formatted_log = "IPU failed:`n$formatted_log"
  $EntryType = 'Error'
}
else {
  $formatted_log = "IPU succeeded:`n$formatted_log"
}

try {
  $params = @{
    LogName   = 'Application'
    Source    = $Source
    EntryType = 'Information'
    EventId   = 1337
    Message   = $formatted_log
  }
  Write-EventLog @params
}
catch {
  throw "Failed to export SCCM Event Log: $_"
}