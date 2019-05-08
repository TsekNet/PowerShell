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

begin {
  # Helper function to change directory to my development workspace
  function Set-Path {
    $Path = 'C:\Tmp\'
    if (-not (Test-Path -Path $Path)) {
      New-Item -ItemType Directory -Force -Path $Path
    }
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

    process {
      try {
        Import-Module -Name $Name -ErrorAction Stop
      }
      catch {
        $lookup = Find-Module -Name $Name
        if (-not $lookup) {
          Write-Error "Module `"$Name`" not found."
          continue
        }
        Install-Module -Name $Name -Scope CurrentUser -Force
        Import-Module -Name $Name
      }
    }
  }

  # Helper function to test prompt elevation
  function Test-IsAdministrator {
    if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
      $script:elevation = "Admin"
    }
    else {
      $script:elevation = "Non-Admin"
    }
  }

  # Download a file from GitHub
  function Get-GitFile {
    [CmdletBinding()]
    param (
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidatePattern('https://raw\.githubusercontent\.com.*')]
      [string]
      $URL
    )

    process {
      return (Invoke-WebRequest -Uri $URL).Content
    }
  }

  # Download Profile/Theme and set them
  function Set-MyTheme {
    [CmdletBinding(SupportsShouldProcess)]
    param (
      [Parameter()]
      [uri]$git_ps_profile_url = 'https://raw.githubusercontent.com/tseknet/PowerShell/master/Profile/Profile.ps1',
      [Parameter()]
      [uri]$git_ps_theme_url = 'https://raw.githubusercontent.com/tseknet/PowerShell/master/Profile/Themes/Beast.psm1'
    )
    $theme_name = ($git_ps_theme_url.AbsolutePath -split '/' | Select-Object -Last 1).Trim()
    $theme_path = "$($ThemeSettings.MyThemesLocation)"
    if (-not(Test-Path -Path $theme_path)) {
      New-Item -ItemType Directory $theme_path
    }
    $local_theme = Get-ChildItem $theme_path | Where-Object { $_.Name -eq $theme_name } | Get-Content
    $git_theme = Get-GitFile $git_ps_theme_url
    if ($local_theme -ne $git_theme) {
      Write-Information "Updating local theme content from github."
      $git_theme | Out-File "$theme_path\$theme_name" -Force
    }
    Set-Theme (Get-Item "$theme_path\$theme_name").BaseName

    # Update local profile from github repo (if current does not match)
    $git_ps_profile = Get-GitFile $git_ps_profile_url.AbsoluteUri
    $local_profile = Get-Content $profile.CurrentUserAllHosts -Raw
    if ($local_profile -ne $git_ps_profile) {
      Write-Warning "Updating local profile from github."
      $git_ps_profile | Out-File $profile.CurrentUserAllHosts -Force
    }
  }
}

#endregion

#region statements

process {
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
}

#endregion

#region execution

end {
  # Admin verification is used for the title window
  Test-IsAdministrator

  # Set the Window Title
  $host.ui.RawUI.WindowTitle = "PowerShell [ $($script:elevation) |
 $(([regex]"\d+\.\d+.\d+").match($psversiontable.psversion).value) |
 $($psversiontable.psedition) |
 $("$env:USERNAME@$env:COMPUTERNAME.$env:USERDOMAIN".ToLower()) ]"

  # Import all my modules
  $my_modules = @('posh-git', 'oh-my-posh', 'Get-ChildItemColor')
  $my_modules | Import-MyModules

  # Set ll and ls alias to use the new Get-ChildItemColor cmdlets
  Set-Alias ll Get-ChildItemColor -Option AllScope
  Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope

  # Set the oh-my-posh theme
  Set-MyTheme

  # Set the current directory to the one set in the function above
  Set-Path
}

#endregion