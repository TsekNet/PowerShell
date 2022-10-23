#Requires -RunAsAdministrator

<#
.SYNOPSIS
  Downloads and installs Windows drivers directly from Manufacturer websites.
.DESCRIPTION
  This script is meant to be invoked during Windows Operating System Deployment
  to install drivers from common Hardware Manufacturers such as Lenovo, Dell,
  HP, etc. This script *can* also be used to update drivers of live systems,
  but may lead to system instability caused by replacing storage, network,
  display, etc. drivers.
.PARAMETER Manufacturer
  The Manufacturer of the device. Must be one of 'Lenovo', 'Dell', 'HP'.
.PARAMETER Model
  The literal regex string that matches a URL on the Manufacturer's website
  pointing to the exact download URL of the driver.
.PARAMETER SkipDownload
  [OPTIONAL] Don't download drivers from the Manufacturer website. Just execute
  drivers that were previously downloaded.
.PARAMETER SkipInstall
  [OPTIONAL] Don't install drivers via pnp. Just download the drivers to
  $env:TEMP and exit.
.EXAMPLE
  .\install_drivers.ps1 -Manufacturer Lenovo -Model 20y0

  Downloads Lenovo driver installer matching the regex 20y0 exact string to
  "$env:TEMP\Lenovo" then installs the drivers from the expanded installer.
.EXAMPLE
  .\install_drivers.ps1 -Manufacturer HP -Model Z440

  Downloads HP driver installer matching the regex Z440 exact string to
  "$env:TEMP\HP" then installs the drivers from the expanded installer.

.EXAMPLE
  .\install_drivers.ps1 -Manufacturer Dell -Model 9380

  Downloads Dell driver installer matching the regex 9380 exact string to
  "$env:TEMP\Dell" then installs the drivers from the expanded installer.
#>

[CmdletBinding()]
param (
  [Parameter(Mandatory)]
  [string]$Manufacturer,
  [Parameter(Mandatory)]
  [string]$Model,
  [Parameter()]
  [switch]$SkipDownload,
  [Parameter()]
  [switch]$SkipInstall
)

function Get-RegexMatch {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory)]
    [string]$Manufacturer,
    [Parameter(Mandatory)]
    [string]$Model
  )

  # manufacturer_uri was manually obtained from manufactorer websites
  # file_regex was manually tested against multiple models
  # match_index is required if we have multiple regex groups
  switch ($Manufacturer) {
    'LENOVO' {
      $manufacturer_uri = 'https://download.lenovo.com/cdrt/td/catalogv2.xml'
      $file_regex = "https.*?$Model.*?exe"
      $match_index = 0
    }
    'DELL' {
      $manufacturer_uri = 'https://www.dell.com/support/kbdoc/en-uk/000180534/dell-family-driver-packs'
      $file_regex = "(?:$Model.*?[\s\S]*?)(https.*?zip)"
      $match_index = 1
    }
    'HP' {
      $manufacturer_uri = 'https://hpia.hpcloud.hp.com/downloads/driverpackcatalog/HP_Driverpack_Matrix_x64.html'
      $file_regex = "(?:$Model.*?)(https.*?exe)"
      $match_index = 1
    }
    default { throw "Manufacturer [$Manufacturer] is not (yet) supported..." }
  }

  try {
    Write-Host "Getting driver download URL from [$manufacturer_uri]"
    $req = Invoke-WebRequest -Uri $manufacturer_uri -UseBasicParsing
  } catch {
    throw "Failed to navigate to [$manufacturer_uri]"
  }

  $regex_search = $req.Content -match $file_regex
  if (-not $regex_search) {
    throw "Failed to find a match for [$file_regex] in [$manufacturer_uri]"
  }

  # URLs have file paths that are seperated by forward slashes...
  # Grab the last item in the split list of items separated by forward slashes,
  # as it's usually the file name.
  $file_name = ($Matches[$match_index] -split '/')[-1]

  return $Matches[$match_index], $file_name
}

function Get-Installer {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory)]
    [string]$DownloadURI,
    [Parameter(Mandatory)]
    [string]$InstallerName
  )
  try {
    Write-Host "Downloading [$DownloadURI] to [$InstallerName]"
    Write-Warning 'This may take a while...'
    Invoke-WebRequest -Uri $DownloadURI -UseBasicParsing -OutFile $InstallerName
  } catch {
    throw "Failed to download [$DownloadURI] to [$InstallerName]"
  }
}

function Expand-Installer {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory)]
    [string]$Manufacturer,
    [Parameter(Mandatory)]
    [string]$InstallerName,
    [Parameter()]
    [string]$Destination
  )

  switch ($Manufacturer) {
    'Lenovo' {
      $arg_list = @('/SP-', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/DIR=$Destination")
    }
    'Dell' {
      try {
        Write-Host "Expanding [$InstallerName] to [$Destination]"
        Expand-Archive -Path $InstallerName -DestinationPath $Destination -Force -ErrorAction Stop
        return
      } catch {
        throw "Failed to expand Dell zip: $_"
      }
    }
    'HP' {
      $arg_list = @('-s', '-f', $Destination)
    }
    default { throw "Manufacturer [$Manufacturer] is not (yet) supported..." }
  }

  Write-Host "Executing [$InstallerName $arg_list]"
  Start-Process -FilePath $InstallerName -ArgumentList $arg_list -Wait
}


function Install-Drivers {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory)]
    [string]$Destination
  )

  $driver_paths = Get-ChildItem $Destination -Recurse -Filter '*.inf'

  if (-not $driver_paths) {
    throw "Failed to locate any drivers (*.inf) in [$Destination]"
  }

  try {
    Write-Host "Installing all drivers under [$Destination]..."

    # https://www.deploymentresearch.com/back-to-basics-pnp-exe-vs-pnpunattend-exe/
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $Destination -Force | Out-Null

    $pnp = "$env:WINDIR\system32\PnPUnattend.exe"

    Write-Host "Executing [$pnp auditSystem /L]"
    $process = Start-Process -FilePath $pnp -ArgumentList @('auditSystem', '/L') -PassThru -Wait
  } catch {
    throw "Failed to install driver with exit code [$($process.ExitCode)]: $_"
  }

  return $process.ExitCode
}

# Set static variable(s)
$TEMP_PATH = "$env:TEMP\$Manufacturer"

# Write-Progress slows downloads in PS 5. Turn it off.
$OldProgressPreference = $ProgressPreference
$global:ProgressPreference = 'SilentlyContinue'

try {
  if (-not (Test-Path $TEMP_PATH)) {
    Write-Host "Creating directory: [$TEMP_PATH]"
    New-Item -ItemType Directory $TEMP_PATH -Force | Out-Null
  }

  if (-not $SkipDownload) {
    $regex_uri, $file_name = Get-RegexMatch -Manufacturer $Manufacturer -Model $Model
    $installer = "$TEMP_PATH\$file_name"

    Get-Installer -DownloadURI $regex_uri -InstallerName $installer

    Expand-Installer -Manufacturer $Manufacturer -InstallerName $installer -Destination $TEMP_PATH
  }

  if (-not $SkipInstall) {
    Install-Drivers -Destination $TEMP_PATH
  }
} catch {
  throw $_
} finally {
  if (-not $SkipInstall) {
    Remove-Item $TEMP_PATH -Force -Recurse -ErrorAction Continue
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force
  }

  $ProgressPreference = $OldProgressPreference
}
