<# 
    .SYNOPSIS
	Enable Custom Portware Laptop Power Config Settings such as don't sleep when lid closed
    
    .NOTES 
    NAME: Set-LaptopPowerCfg.ps1
    VERSION: 1.0
    AUTHOR: Daniel Tsekhanskiy
    LASTEDIT: 10/7/2016
#>


#Import Laptop Power Profile. Includes do not sleep when lid closed on laptops
powercfg -import "Path\to\PowerPlan.pow" 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Set Power Profile as Active Profile
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Set "Do Nothing" for when the lid is closed when connected to power
powercfg -SETACVALUEINDEX 381b4222-f694-41f0-9685-ff5bb260df2e 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.MessageBox]::Show("Press ok to continue. . .")
