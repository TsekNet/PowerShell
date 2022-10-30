<#
.SYNOPSIS
  Export SCCM logs to the Event Log.
.DESCRIPTION
  Regex Parse a log file and dump to Event Log.
.PARAMETER LogPath
  Folder to recursively search for the LogFile.
.PARAMETER LogFile
  Location of log file on the local system.
.PARAMETER FailureString
  The string used to determine when the OS Upgrade failed.
.PARAMETER Source
  Specifies the Event Log source for writing logs.
.PARAMETER EntryType
  Specifies the Event Log entry type for writing logs.
#>
[CmdletBinding()]
param (
  [System.IO.FileInfo]$LogPath = "$env:WINDIR\CCM\Logs\Smstslog",
  [System.IO.FileInfo]$LogFile = 'smsts.log',
  [string]$FailureString = 'Task sequence execution failed with error code',
  [string]$Source = 'InPlaceUpgrade',
  [string]$EntryType = 'Information'
)

# Create Log Source if necessary
if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
  try {
    New-EventLog -LogName Application -Source $Source
  } catch {
    throw "Failed to create log source: $_"
  }
}

$log = "$LogPath\$LogFile"

# Exit if there is no log file to write to.
if (-not (Test-Path $log)) {
  throw "Failed to locate log file: $log"
}

# Strip the CMTRACE loginfo from the log file. Logs are wrapped in
# <!\[LOG\[ DATA \]LOG\]!>. All we want is the DATA. Also helps keep
# under the 32KB limit for Event Log messages.
try {
  $formatted_log = Get-Content $log -Raw |
    ForEach-Object { $_ -replace '<!\[LOG\[', '' } |
      ForEach-Object { $_ -replace '\]LOG\]!>(.*)', '' }
} catch {
  throw "Failed to read log file '$log' with error $_"
}

$length = $formatted_log.Length
# Optionally trim log to under max Event Log size (32KB) to grab latest logs.
if ($length -gt 32766) {
  $formatted_log = $formatted_log[($length - 31000)..$length] -join ''
}

# Change log level and prepend custom success/failure string.
if ($formatted_log -match $FailureString) {
  $formatted_log = "Failure detected:`n$formatted_log"
  $EntryType = 'Error'
} else {
  $formatted_log = "Succeeded:`n$formatted_log"
}

try {
  $params = @{
    LogName   = 'Application'
    Source    = $Source
    EventId   = 1337
    EntryType = $EntryType
    Message   = $formatted_log
  }
  Write-EventLog @params -ErrorAction Stop
} catch {
  throw "Failed to export Event Log from file: $_"
}