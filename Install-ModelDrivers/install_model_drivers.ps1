﻿#Requires -RunAsAdministrator

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
  The Manufacturer of the device. Must be one of 'LENOVO', 'DELL', 'HP', 'MICROSOFT'.
.PARAMETER Model
  The literal regex string that matches a URL on the Manufacturer's website
  pointing to the exact download URL of the driver.
.PARAMETER SkipDownload
  [OPTIONAL] Don't download drivers from the Manufacturer website. Just execute
  drivers that were previously downloaded.
.PARAMETER SkipPnP
  [OPTIONAL] Don't install drivers via pnp.
.PARAMETER SkipCleanup
  [OPTIONAL] Don't cleanup temporary folders or registry keys.
.EXAMPLE
  .\install_model_drivers.ps1 -Manufacturer Lenovo -Model 20y0

  Downloads Lenovo driver installer matching the regex 20y0 exact string to
  "$env:TEMP\Lenovo" then installs the drivers from the expanded installer.
.EXAMPLE
  .\install_model_drivers.ps1 -Manufacturer HP -Model Z440

  Downloads HP driver installer matching the regex Z440 exact string to
  "$env:TEMP\HP" then installs the drivers from the expanded installer.
.EXAMPLE
  .\install_model_drivers.ps1 -Manufacturer Dell -Model 9380

  Downloads Dell driver installer matching the regex 9380 exact string to
  "$env:TEMP\Dell" then installs the drivers from the expanded installer.
.EXAMPLE
  .\install_model_drivers.ps1 -Manufacturer Microsoft -Model
  'Surface Laptop 4 with Intel Processor'

  Downloads Microsoft driver installer matching the regex '
  Surface Laptop 4 with Intel Processor' exact string to "$env:TEMP\Microsoft"
  then installs the drivers via the msi installer.
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
  [switch]$SkipPnP,
  [Parameter()]
  [switch]$SkipCleanup
)

function Get-URL {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory)]
    [string]$URI,
    [Parameter(Mandatory)]
    [string]$FileRegEx,
    [Parameter(Mandatory)]
    [int]$MatchIndex
  )
  try {
    Write-Host "Getting driver download URL from [$URI]"
    $req = Invoke-WebRequest -Uri $URI -UseBasicParsing
  } catch {
    throw "Failed to navigate to [$URI]"
  }

  $regex_search = $req.Content -match $FileRegEx
  if (-not $regex_search) {
    throw "Failed to find a match for [$FileRegEx] in [$URI]"
  }

  # URLs have file paths that are seperated by forward slashes...
  # Grab the last item in the split list of items separated by forward slashes,
  # as it's usually the file name.
  $file_name = ($Matches[$MatchIndex] -split '/')[-1]

  return $Matches[$MatchIndex], $file_name
}

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
      # Example: <SCCM os="win10" version="1909" crc="e2c56fbad5b2689fbe6246dcfd68a72616a0c08d2dd915ed8a88802291cb89a2">https://download.lenovo.com/pccbbs/mobiles/tp_x1carbon_mt20xw-20xx-x1yoga_mt20xy-20y0_w1064_1909_202107.exe</SCCM>
      $file_regex = "https.*?$Model.*?exe"
      $match_index = 0
    }
    'DELL' {
      $manufacturer_uri = 'https://www.dell.com/support/kbdoc/en-uk/000180534/dell-family-driver-packs'
      # Example: <td colspan="1" rowspan="1">9330</td> ... <a href="https://fta.dell.com/0/DIA/Drivers/win11_latitudee14mlk9330_a03.zip" target="_self">A03 (09/26/22)</a>
      $file_regex = "(?:$Model.*?[\s\S]*?)(https.*?zip)"
      $match_index = 1
    }
    'HP' {
      $manufacturer_uri = 'https://hpia.hpcloud.hp.com/downloads/driverpackcatalog/HP_Driverpack_Matrix_x64.html'
      # Example: <p>HP ProBook x360 440 G1 Notebook PC</p> ... <a href="https://ftp.hp.com/pub/softpaq/sp114001-114500/sp114238.exe" ... </a>
      $file_regex = "(?:$Model.*?)(https.*?exe)"
      $match_index = 1
    }
    # Microsoft hides their links behind (at least) two clicks...
    'MICROSOFT' {
      $manufacturer_uri = 'https://learn.microsoft.com/en-us/surface/manage-surface-driver-and-firmware-updates'
      # Example: <a href="https://www.microsoft.com/download/details.aspx?id=102924" data-linktype="external">Surface Laptop 4 with Intel Processor</a>
      $file_regex = "(\d{6})(?:`" data-linktype=`"external`">$Model)"
      $match_index = 1
      $id, $null = Get-URL -URI $manufacturer_uri -FileRegEx $file_regex -MatchIndex $match_index

      $manufacturer_uri = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=$id"
      # Example: <a ... href="https://download.microsoft.com/download/f/7/0/f70b3d0a-59b1-4842-9130-0c152bb738ba/SurfaceLaptop4_Win11_22000_22.093.37381.0.msi" ...>click here to download manually</strong></a>
      $file_regex = '(http.*?\.msi)'
      $match_index = 0
    }
    default { throw "Manufacturer [$Manufacturer] is not (yet) supported..." }
  }

  return Get-URL -URI $manufacturer_uri -FileRegEx $file_regex -MatchIndex $match_index
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

function Invoke-Installer {
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
      $arg_list = @('/SP-', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/DIR=$Destination", '/LOG')
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
    'MICROSOFT' {
      $arg_list = @('/qn', '/norestart', '/l*v', "$Destination\driver_install.log")
    }
    default { throw "Manufacturer [$Manufacturer] is not (yet) supported..." }
  }

  Write-Host "Executing [$InstallerName $arg_list]"
  Start-Process -FilePath $InstallerName -ArgumentList $arg_list -Wait
}


function Invoke-PnP {
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
    New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths' -Name 1 -Force | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1' -Name Path -Value $Destination -Force | Out-Null

    $pnp = "$env:WINDIR\system32\PnPUnattend.exe"

    Write-Host "Executing [$pnp auditSystem /L]"
    $process = Start-Process -FilePath $pnp -ArgumentList @('auditSystem', '/L') -NoNewWindow -PassThru -Wait
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
  if ($SkipDownload) {
    Write-Host 'Skipping download...'
  } else {
    if (-not (Test-Path $TEMP_PATH)) {
      Write-Host "Creating directory: [$TEMP_PATH]"
      New-Item -ItemType Directory $TEMP_PATH -Force | Out-Null
    }

    $regex_uri, $file_name = Get-RegexMatch -Manufacturer $Manufacturer -Model $Model
    $installer = "$TEMP_PATH\$file_name"

    Get-Installer -DownloadURI $regex_uri -InstallerName $installer

    Invoke-Installer -Manufacturer $Manufacturer -InstallerName $installer -Destination $TEMP_PATH
  }

  # Surface does not install drivers via PnP, just via an MSI installer.
  if ($SkipPnP -or ($Model -like '*Surface*')) {
    Write-Host 'Skipping PnP installation...'
  } else {
    Invoke-PnP -Destination $TEMP_PATH
  }
} catch {
  throw $_
} finally {
  if ($SkipCleanup) {
    Write-Host 'Skipping cleanup...'
  } else {
    Write-Host 'Cleaning up...'
    Remove-Item $TEMP_PATH -Force -Recurse -ErrorAction Continue

    if ($Model -notlike '*Surface*') {
      Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1' -Recurse -Force
    }
  }

  $ProgressPreference = $OldProgressPreference
}
