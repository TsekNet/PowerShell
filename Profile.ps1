#requires -module powerline

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
$Title = "PowerShell [$($n) | $(([regex]"\d+\.\d+.\d+").match($psversiontable.psversion).value) | $($psversiontable.psedition)]"

$Path = 'C:\Tmp\'
if (-not (Test-Path -Path $Path)) {
  New-Item -ItemType Directory -Force -Path $Path
}
Set-Location $Path

$global:prompt = @(
  { "`t" } # On the first line, right-justify
  { New-PowerLineBlock (Get-Elapsed) -ErrorBackgroundColor DarkRed -ErrorForegroundColor White -ForegroundColor Black -BackgroundColor DarkGray }
  { Get-Date -f "T" }
  { "`n" } # Start another line
  { $MyInvocation.HistoryId }
  { "&Gear;" * $NestedPromptLevel }
  { $pwd.Drive.Name }
  { (($pwd.Path).Replace("$($pwd.Drive.Name):\", '')).Replace('\', '' + [char]::ConvertFromUtf32(0xE0B1) + '') }
  { "`n" } # Start another line
  { New-PromptText { "$(New-PromptText -Fg Red -EFg White "&hearts;$([char]27)[30m")" } -Bg White -EBg Red -Fg Black }
)

Write-Output $Title
Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -Title { $Title } -Colors "White", "Gray", "Blue", "Cyan", "Cyan", "DarkBlue", "DarkBlue", "DarkCyan"

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

# Allow Emoji's
$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'