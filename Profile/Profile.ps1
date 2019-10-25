<#
.SYNOPSIS
  @TsekNet PowerShell Profile.

.DESCRIPTION
  My heavily customized PowerShell profile. Feel free to use and distrubute as
  you see fit. Always improving this, if you catch any errors, or see where I
  can improve this, please let me know!

  To use this profile, simply place this file in any of your $profile
  directories and restart your PowerShell console
  (Ex: $profile.CurrentUserAllHosts)

.LINK
  TsekNet.com
  GitHub.com/TsekNet
  Twitter.com/TsekNet
#>

#region function declarations

# Helper function to change directory to my development workspace
function Set-Path {
  [CmdletBinding()]
  Param(
    [ValidateScript( {
        if (-Not ($_ | Test-Path) ) {
          Write-Verbose "Creating default location $_"
          New-Item -ItemType Directory -Force -Path $_
        }
        return $true
      })]
    [System.IO.FileInfo]$Path
  )
  Set-Location $Path
}

# Helper function to copy the last command entered
function Copy-LastCommand {
  Get-History -id $(((Get-History) | Select-Object -Last 1 |
      Select-Object ID -ExpandProperty ID)) |
  Select-Object -ExpandProperty CommandLine |
  clip
}

# Helper function to ensure all modules are loaded, with error handling
function Import-MyModules {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]
    $Name
  )

  try {
    Import-Module -Name $Name -ErrorAction Stop
  } catch {
    $lookup = Find-Module -Name $Name
    if (-not $lookup) {
      Write-Error "Module `"$Name`" not found."
      continue
    }
    Install-Module -Name $Name -Scope CurrentUser -Force
    Import-Module -Name $Name
  }
}

# Helper function to test prompt elevation
function Test-IsAdministrator {
  if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    $script:elevation = "Admin"
  } else {
    $script:elevation = "Non-Admin"
  }
}

# Helper function to set the window title
function Set-WindowTitle {
  $host_title = [ordered]@{
    'Elevation' = $elevation
    'Session'   = "$env:USERNAME@$env:COMPUTERNAME".ToLower()
  }

  $host.ui.RawUI.WindowTitle = "PowerShell [ $($host_title.Values -join ' | ') ]"
}

  $host.ui.RawUI.WindowTitle = "PowerShell [ $($host_title.Values -join ' | ') ]"
}

# Download Files from Github
function Import-GitRepo {
  <#
  .Synopsis
    This function will download a Github Repository without using Git
  .DESCRIPTION
    This function will download files from Github without using Git.  You will need to know the Owner, Repository name, branch (default master),
    and FilePath.  The Filepath will include any folders and files that you want to download.
  .EXAMPLE
    Import-GitRepo -Owner MSAdministrator -Repository WriteLogEntry -Verbose -FilePath `
        'WriteLogEntry.psm1',
        'WriteLogEntry.psd1',
        'Public',
        'en-US',
        'en-US\about_WriteLogEntry.help.txt',
        'Public\Write-LogEntry.ps1'
  #>
  [CmdletBinding()]
  [Alias()]
  [OutputType([int])]
  Param
  (
    # Repository owner
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
    [string]$Owner,

    # Name of the repository
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
    [string]$Repository,

    # Branch to download from
    [Parameter(ValueFromPipelineByPropertyName, Position = 2)]
    [string]$Branch = 'master',

    # List of files/paths to download
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 3)]
    [string[]]$FilePath,

    # List of posh-git themes to download
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 4)]
    [string[]]$ThemeName,

    # List of posh-git themes to download
    [Parameter(ValueFromPipelineByPropertyName, Position = 5)]
    [string]$ProfileFile = $profile.CurrentUserAllHosts
  )

  $modulespath = ($env:psmodulepath -split ";")[0]
  $PowerShellModule = "$modulespath\$Repository"
  $wc = New-Object System.Net.WebClient
  $wc.Encoding = [System.Text.Encoding]::UTF8
  if (-not(Test-Path $PowerShellModule)) {
    Write-Verbose "Creating module directory"
    New-Item -Type Container -Path $PowerShellModule -Force | Out-Null
  }

  if (-not(Test-Path $ProfileFile)) {
    Write-Verbose "Creating profile"
    New-Item -Path $ProfileFile -Force | Out-Null
  }

  foreach ($item in $FilePath) {
    if ($item -like '*.*') {
      $url = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch/$item"
      Write-Verbose "Attempting to download from '$url'"
      if ($item -like "*$ThemeName.psm1") {
        Write-Verbose "'$item' Theme found in FilePath"
        $fullpath = "$(Join-Path -Path (Get-ChildItem $profile.CurrentUserAllHosts).Directory.FullName -ChildPath 'PoshThemes')\$ThemeName.psm1"
        if (-not(Test-Path $fullpath)) {
          Write-Verbose "Creating file '$fullpath'"
          New-Item -ItemType File -Force -Path $fullpath | Out-Null
        }
        ($wc.DownloadString("$url")) | Out-File $fullpath
      } elseif ($item -like '*profile.ps1') {
        Write-Verbose "'$item' Profile found in FilePath"
        New-Item -ItemType File -Force -Path $ProfileFile | Out-Null
        Write-Verbose "Created file '$ProfileFile'"
        ($wc.DownloadString("$url")) | Out-File "$ProfileFile"
      } else {
        Write-Verbose "'$item' found in FilePath"
        New-Item -ItemType File -Force -Path "$PowerShellModule\$item" | Out-Null
        Write-Verbose "Created file '$PowerShellModule\$item'"
        ($wc.DownloadString("$url")) | Out-File "$PowerShellModule\$item"
      }
    } else {
      New-Item -ItemType Container -Force -Path "$PowerShellModule\$item" | Out-Null
      Write-Verbose "Created file '$PowerShellModule\$item'"
      $url = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch/$item"
      Write-Verbose "Attempting to download from $url"
    }
  }
}


# Helper function to log all PowerShell invocations
function Start-TranscriptLog {
  [CmdletBinding()]
  Param (
    [System.IO.FileInfo]$TranscriptDir = "$(Get-ChildItem $profile.CurrentUserAllHosts |
    Select-Object -ExpandProperty Directory)\Transcripts\$(Get-Date -Format yyyy)\$(Get-Date -UFormat %B)",
    [String]$TranscriptName = "$(Get-Date -Format dd-MM-yyyy).log"
  )

  # Make variable available at all times
  $global:TranscriptPath = "$TranscriptDir\$TranscriptName"
  if ($TranscriptPath) {
    Start-Transcript -Path $TranscriptPath -Append | Out-Null
  } else {
    New-Item -ItemType Directory -Path $TranscriptDir -Force | Out-Null
    Start-Transcript -Path $TranscriptPath | Out-Null
  }

  Write-Output "`$TranscriptPath: $TranscriptPath"
}

#endregion

#region statements

# If it's Windows PowerShell, we can turn on Verbose output if you're holding shift
if ("Desktop" -eq $PSVersionTable.PSEdition) {
  # Check SHIFT state ASAP at startup so I can use that to control verbosity :)
  Add-Type -Assembly PresentationCore, WindowsBase
  try {
    if ([System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftShift) -OR
      [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::RightShift)) {
      $VerbosePreference = "Continue"
    }
  } catch {
    # If that didn't work ... oh well.
  }
}

#endregion

#region execution

Write-Verbose '==Logging all PowerShell output to `$TranscriptPath.=='
Start-TranscriptLog

Write-Verbose '==Checking if PowerShell was started as Administrator.=='
Test-IsAdministrator

Write-Verbose '==Setting the PowerShell console title.=='
Set-WindowTitle

Write-Verbose '==Attempting to import modules required for profile.=='
$my_modules = @('posh-git', 'oh-my-posh', 'Get-ChildItemColor', 'PSWriteHTML')
$my_modules | Import-MyModules

Write-Verbose '==Attempting to download latest files from GitHub.=='
Import-GitRepo -Owner tseknet -Repository PowerShell -FilePath `
  'Profile/Profile.ps1',
'Profile/Themes/TsekNet.psm1' -ThemeName 'TsekNet'

Write-Verbose '==Make ll and ls use the Get-ChildItemColor module instead.=='
Set-Alias ll Get-ChildItemColor -Option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope

Write-Verbose '==Setting custom oh-my-posh theme.=='
Set-Theme 'TsekNet'

Write-Verbose '==Setting the default directory for new PowerShell consoles.=='
Set-Path -Path 'C:\Tmp'

#endregion
