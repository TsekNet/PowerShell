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
#>

# Helper function to change directory to my development workspace
function Set-Path {
  $Path = 'C:\Tmp\'
  if (-not (Test-Path -Path $Path)) {
    New-Item -ItemType Directory -Force -Path $Path
  }
  Set-Location $Path
}

# Ensure that required modules are loaded
try {
  Import-Module Get-ChildItemColor -ErrorAction Stop
}
catch {
  Install-Module Get-ChildItemColor -Scope CurrentUser -Repository PSGallery
  Import-Module Get-ChildItemColor
}

# Set ll and ls alias to use the new Get-ChildItemColor cmdlets
Set-Alias ll Get-ChildItemColor -Option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope

# Helper function to test prompt elevation
function Test-IsAdministrator {
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (Test-IsAdministrator) {
  $n = "Administrator"
}
else {
  $n = "Non-Admin"
}
Write-Output "PowerShell [$($n) | $(([regex]"\d+\.\d+.\d+").match($psversiontable.psversion).value) | $($psversiontable.psedition)]"

# If it's Windows PowerShell, we can turn on Verbose output if you're holding shift
if ("Desktop" -eq $PSVersionTable.PSEdition) {
  # Check SHIFT state ASAP at startup so I can use that to control verbosity :)
  Add-Type -Assembly PresentationCore, WindowsBase
  try {
    if ([System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftShift) -OR
      [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::RightShift)) {
      $VerbosePreference = "Continue"
    }
  }
  catch {
    # If that didn't work ... oh well.
  }
}

# PowerLine Settings
# Ensure that required modules are loaded
try {
  Import-Module posh-git -ErrorAction Stop
}
catch {
  Install-Module posh-git -Scope CurrentUser -Repository PSGallery
  Import-Module posh-git
}
# Ensure that required modules are loaded
try {
  Import-Module oh-my-posh -ErrorAction Stop
}
catch {
  Install-Module oh-my-posh -Scope CurrentUser -Repository PSGallery
  Import-Module oh-my-posh
}

# Set the oh-my-posh theme
Set-Theme Paradox

# Remove username from PowerLine
Set-Variable -Name DefaultUser -Value 'dantsek' -Scope Global

# Set the current directory to the one set in the function above
Set-Path