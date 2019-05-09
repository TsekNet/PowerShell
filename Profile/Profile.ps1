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

  # Download Profile/Theme and set them<#
  function Get-GithubRepository {
    <#
.Synopsis
   This function will download a Github Repository without using Git
.DESCRIPTION
   This function will download files from Github without using Git.  You will need to know the Owner, Repository name, branch (default master),
   and FilePath.  The Filepath will include any folders and files that you want to download.
.EXAMPLE
   Get-GithubRepository -Owner MSAdministrator -Repository WriteLogEntry -Verbose -FilePath `
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
      # Please provide the repository owner
      [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
      [string]$Owner,

      # Please provide the name of the repository
      [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
      [string]$Repository,

      # Please provide a branch to download from
      [Parameter(ValueFromPipelineByPropertyName, Position = 2)]
      [string]$Branch = 'master',

      # Please provide a list of files/paths to download
      [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 3)]
      [string[]]$FilePath,

      # Please provide a list of files/paths to download
      [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 4)]
      [string[]]$ThemeName
    )

    Begin {
      $modulespath = ($env:psmodulepath -split ";")[0]
      $PowerShellModule = "$modulespath\$Repository"
      Write-Verbose "Creating module directory"
      New-Item -Type Container -Force -Path $PowerShellModule | out-null
      Write-Verbose "Downloading and installing"
      $wc = New-Object System.Net.WebClient
      $wc.Encoding = [System.Text.Encoding]::UTF8
    }
    Process {
      foreach ($item in $FilePath) {
        Write-Verbose -Message "$item in FilePath"
        if ($item -like '*.*') {
          $url = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch/$item"
          Write-Verbose -Message "Attempting to download from $url"
          if ($item -like "*$ThemeName.psm1") {
            $poshpath = Join-Path -Path "$($env:PSModulePath -split ';' | Select-Object -First 1)" -ChildPath "oh-my-posh\*.*.***\Themes" -Resolve
            $fullpath = $poshpath + '\' + $ThemeName + '.psm1'

            Write-Verbose -Message "Attempting to create $fullpath"
            if (-not(Test-Path $fullpath)) {
              New-Item -ItemType File -Force -Path $fullpath | Out-Null
            }
            ($wc.DownloadString("$url")) | Out-File $fullpath
          }
          else {
            Write-Verbose -Message "Attempting to create $PowerShellModule\$item"
            New-Item -ItemType File -Force -Path "$PowerShellModule\$item" | Out-Null
            ($wc.DownloadString("$url")) | Out-File "$PowerShellModule\$item"
          }
        }
        else {
          Write-Verbose -Message "Attempting to create $PowerShellModule\$item"
          New-Item -ItemType Container -Force -Path "$PowerShellModule\$item" | Out-Null
          $url = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch/$item"
          Write-Verbose -Message "Attempting to download from $url"
        }
      }
    }
    End {
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
  Get-GithubRepository -Owner tseknet -Repository PowerShell -FilePath `
    'Profile/Profile.ps1',
  'Profile/Themes/Fish.psm1' -ThemeName 'Fish' -Verbose

  # Set the current directory to the one set in the function above
  Set-Path
}

#endregion