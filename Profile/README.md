# TsekNet's Profile

My personal, heavily customized PowerShell profile. Feel free to use and distrubute it as
you see fit. I am always improving this, so if you catch any errors, or see where I
can improve, please let me know!

To use this profile, simply place this file in any of your $profile
directories and restart your PowerShell console
(Ex: $profile.CurrentUserAllHosts)

## Screenshots

PowerShell running in an administrative window while working in C:\tmp

![PowerShell Admin](PowerShell_Admin_No_Git.png)

PowerShell running in a non-admin window while working on a git repo

![PowerShell Non-Admin](PowerShell_NoAdmin_Git.png)

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Installation

1. Copy the following into a PowerShell prompt:

```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/tseknet/PowerShell/master/Profile/Profile.ps1' -OutFile $profile.CurrentUserAllHosts
```

2. [Powerline fonts](https://github.com/PowerLine/fonts) are required for the extra extended characters with the nice angled separators you see in the screenshots. To install Powerline fonts using powershell run the following:

```powershell
git clone https://github.com/PowerLine/fonts
cd fonts
.\install.ps1
```

3. Restart PowerShell (or run ```powershell & $profile.CurrentUserAllHosts```)

*NOTE* When running this for the first time, the startup will be slower, as it is installing all the required modules.

### Imported Modules

The following modules will be installed by default:

```powershell {.good}
posh-git
oh-my-posh
Get-ChildItemColor
```

## What's included

1. Set the PowerShell Window Title with useful information such as elevation and version.
1. Install/Import modules listed above.
1. Overwrite ll / ls commands with Get-ChildItemColor for better output
1. Download/Set personal theme [TsekNet.psm1](Themes/TsekNet.psm1)
1. Set default path

## Troubleshooting

If you run into any errors, $Error[0] will have the latest error message for troubleshooting.

## Contributing

Feel free to submit a pull request if you see any issues.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## Acknowledgments

* Hat tip to anyone whose code was used
* etc
