<# 
    .SYNOPSIS
    Save Path environmental variable pre-java install for later restoration

    .NOTES 
    NAME: Savepath.ps1
	VERSION: 1.0
    AUTHOR: Daniel Tsekhanskiy
    LASTEDIT: 3/1/16
#>

#If Temp dir does not exist on main drive, create it.
md -force $env:TEMP

# Save the path environmental variable to an xml file in Temp for later use in Restorepath.ps1
$FileName = "$env:TEMP\path.xml"
$SavePath = $env:Path | Export-Clixml $FileName

# Export the CurrentVersion Registry Value for later restore
reg export "HKLM\SOFTWARE\JavaSoft\Java Runtime Environment" $env:TEMP\CurrentVersion.reg /y