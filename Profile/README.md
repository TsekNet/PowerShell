# TsekNet's Profile

My heavily customized PowerShell profile. Feel free to use and distrubute as
you see fit. Always improving this, if you catch any errors, or see where I
can improve this, please let me know!

To use this profile, simply place this file in any of your $profile
directories and restart your PowerShell console
(Ex: $profile.CurrentUserAllHosts)

## Screenshots

PowerShell running in an administrative window while working in C:\tmp

![](PowerShell_Admin_No_Git.png)

PowerShell running in a non-admin window while working on a git repo

![](PowerShell_NoAdmin_Git.png)

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

The following modules are required:

```powershell {.good}
posh-git
oh-my-posh
Get-ChildItemColor
```

### Installing

1. Download files in this repo
2. Place the profile.ps1 in your preffered $profile location
3. Install the required modules listed above
4. Copy Beast.ps1 into the oh-my-posh themes directory
5. Restart PowerShell

*NOTE* If you run into any errors, $Error[0] will have the latest error
message for troubleshooting.

## Contributing

Feel free to submit a pull request if you see any issues.

## License

This project is licensed under the MIT License - see the [LICENSE.md](../LICENSE) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* etc
