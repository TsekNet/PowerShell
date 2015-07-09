 <# 
    .SYNOPSIS
     Autoinventory script. Gets Computer name, Logged in user, Serial Number, Model, Version of Windows,
	 Version of Office, Visual Studio, Visio, Project

    .NOTES 
     NAME: Get-PCInfo.ps1
	 VERSION: 1.0
     AUTHOR: Dumplati
     LASTEDIT: 7/8/2015
#>
 
$hostname = hostname
$user = whoami
$user2 = $env:username
$product = wmic product
$file = "Path\to\compinfo.csv"
$tempfile = "Path\to\compinfo.csv"
$windows = systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
$serial = (@(wmic csproduct get identifyingnumber) -join ',')
$serial2 = $serial.Replace("IdentifyingNumber", "")
$serial3 = $serial2.Replace(",", "")
$serial4 = $serial3.Replace(" ", "")
$model = (@(wmic computersystem get model) -join ',')
$model2 = $model.Replace("Model", "")
$model3 = $model2.Replace(",","")
$model4 = $model3.Replace(" ","")
$windows2 = "Windows Version not checked by script."
$Office = "No Office"
$Visio = "No Visio"
$Project = "No Project"
$Visual = "No Visual Studio"
if ($windows -Match "Microsoft Windows 7 Starter") {$windows2 = "Windows 7 Starter"}
if ($windows -Match "Microsoft Windows 7 Home Basic") {$windows2 = "Windows 7 Home Basic"}
if ($windows -Match "Microsoft Windows 7 Home Premium") {$windows2 = "Windows 7 Home Premium"}
if ($windows -Match "Microsoft Windows 7 Professional") {$windows2 = "Windows 7 Professional"}
if ($windows -Match "Microsoft Windows 7 Enterprise") {$windows2 = "Windows 7 Enterprise"}
if ($windows -Match "Microsoft Windows 7 Ultimate") {$windows2 = "Windows 7 Ultimate"}
if ($windows -Match "Microsoft Windows 8 RT") {$windows2 = "Windows 8 RT"}
if ($windows -Match "Microsoft Windows 8 Professional") {$windows2 = "Windows 8 Professional"}
if ($windows -Match "Microsoft Windows 8 Enterprise") {$windows2 = "Windows 8 Enterprise"}
if ($windows -Match "Microsoft Windows 8 Standard") {$windows2 = "Windows 8 Standard"}
if ($windows -Match "Microsoft Windows 8.1 RT") {$windows2 = "Windows 8.1 RT"}
if ($windows -Match "Microsoft Windows 8.1 Pro") {$windows2 = "Windows 8.1 Professional"}
if ($windows -Match "Microsoft Windows 8.1 Ent") {$windows2 = "Windows 8.1 Enterprise"}
if ($windows -Match "Microsoft Windows 8.1 Sta") {$windows2 = "Windows 8.1 Standard"}
if ($windows -Match "Microsoft Windows Server 2012 Standard") {$windows2 = "Windows Server 2012 Standard"}
if ($windows -Match "Microsoft Windows Server 2012 R2 Standard") {$windows2 = "Windows Server 2012 R2 Standard"}
if ($windows -Match "Microsoft Windows Server 2012 Datacenter") {$windows2 = "Windows Server 2012 Datacenter"}
if ($windows -Match "Microsoft Windows Server 2012 R2 Datacenter") {$windows2 = "Windows Server 2012 R2 Datacenter"}
if ($windows -Match "Microsoft Windows Server 2012 Essentials") {$windows2 = "Windows Server 2012 Essentials"}
if ($windows -Match "Microsoft Windows Server 2012 R2 Essentials") {$windows2 = "Windows Server 2012 R2 Essentials"}
if ($windows -Match "Microsoft Windows Server 2012 Foundation") {$windows2 = "Windows Server 2012 Foundation"}
if ($windows -Match "Microsoft Windows Server 2012 R2 Foundation") {$windows2 = "Windows Server 2012 R2 Foundation"}
if ($windows -Match "Microsoft Windows Server 2008 R2 Datacenter") {$windows2 = "Windows Server 2008 R2 Datacenter"}
if ($windows -Match "Microsoft Windows Server 2008 R2 Enterprise") {$windows2 = "Windows Server 2008 R2 Enterprise"}
if ($windows -Match "Microsoft Windows Server 2008 R2 Web Edition") {$windows2 = "Windows Server 2008 R2 Web Edition"}
if ($windows -Match "Microsoft Windows Server 2008 R2 Standard") {$windows2 = "Windows Server 2008 R2 Standard"}
if ($windows -Match "Microsoft Windows Server 2008 Datacenter") {$windows2 = "Windows Server 2008 Datacenter"}
if ($windows -Match "Microsoft Windows Server 2008 Enterprise") {$windows2 = "Windows Server 2008 Enterprise"}
if ($windows -Match "Microsoft Windows Server 2008 Web Edition") {$windows2 = "Windows Server 2008 Web Edition"}
if ($windows -Match "Microsoft Windows Server 2008 Standard") {$windows2 = "Windows Server 2008 Standard"}
if ($product -Match "Microsoft Office Professional Plus 2013") {$Office = "Office Professional Plus 2013"}
if ($product -Match "Microsoft Office Professional 2013") {$Office = "Office Professional 2013"}
if ($product -Match "Microsoft Office Standard 2013") {$Office = "Office Standard 2013"}
if ($product -Match "Microsoft Office Professional Plus 2010") {$Office = "Office Professional Plus 2010"}
if ($product -Match "Microsoft Office Professional 2010") {$Office = "Office Professional 2010"}
if ($product -Match "Microsoft Office Standard 2010") {$Office = "Office Standard 2010"}
if ($product -Match "Microsoft Office Home and Business 2010") {$Office = "Office Home and Business 2010"}
if ($product -Match "Microsoft Office Ultimate 2007") {$Office = "Office Ultimate 2007"}
if ($product -Match "Microsoft Office Professional 2007") {$Office = "Office Professional 2007"}
if ($product -Match "Microsoft Visio Professional 2013") {$Visio = "Visio Professional 2013"}
if ($product -Match "Microsoft Visio Standard 2013") {$Visio = "Visio Standard 2013"}
if ($product -Match "Microsoft Visio Professional 2010") {$Visio = "Visio Professional 2010"}
if ($product -Match "Microsoft Visio Standard 2010") {$Visio = "Visio Standard 2010"}
if ($product -Match "Microsoft Project Professional 2013") {$Project = "Project Professional 2013"}
if ($product -Match "Microsoft Project Standard 2013") {$Project = "Project Standard 2013"}
if ($product -Match "Microsoft Project Professional 2010") {$Project = "Project Professional 2010"}
if ($product -Match "Microsoft Project Standard 2010") {$Project = "Project Standard 2010"}
if ($product -Match "Microsoft Visual Studio Professional 2012") {$Visual = "Visual Studio Professional 2012"}
if ($product -Match "Microsoft Visual Studio Ultimate 2012") {$Visual = "Visual Studio Ultimate 2012"}
if ($product -Match "Microsoft Visual Studio Professional 2010") {$Visual = "Visual Studio Professional 2010"}
if ($product -Match "Microsoft Visual Studio Ultimate 2010") {$Visual = "Visual Studio Ultimate 2010"}
if ($product -Match "Microsoft Visual Studio Professional 2005") {$Visual = "Visual Studio Professional 2005"}
$csv = new-object PSObject
$csv | add-member NoteProperty Hostname $hostname
$csv | add-member NoteProperty User $user
$csv | add-member NoteProperty SerialNumber $serial4
$csv | add-member NoteProperty Model $model4
$csv | add-member NoteProperty WindowsVersion $windows2
$csv | add-member NoteProperty OfficeVersion $Office
$csv | add-member NoteProperty VisioVersion $Visio
$csv | add-member NoteProperty ProjectVersion $Project
$csv | add-member NoteProperty VisualVersion $Visual
$csvimport = @(Import-CSV $file)
 
if ($csvimport -Match $hostname -Match $user2 -Match $serial4 -Match $model4 -Match $windows2 -Match $Office -Match $Visio -Match $Project -Match $Visual){
exit
}
 
if ($csvimport -Match $hostname -Match $user2 -Match $Office) {$oah = "Exists"} else {
$oah = "Does notexist"
Import-Csv $file `  | ? { $hostname -notcontains $_."Hostname" } `  | Export-Csv $tempfile -NoTypeInformation
Import-Csv $tempfile `  | ? { $hostname -notcontains $_."Hostname" } `  | Export-Csv $file -NoTypeInformation
$csvimport = @(Import-CSV $file)
$csvimport + $csv | export-csv "$file" -Force
exit
}
 
if ($csvimport -Match $hostname -Match $user2 -Match $Visio) {$vah = "Exists"} else {
$vah = "Does notexist"
Import-Csv $file `  | ? { $hostname -notcontains $_."Hostname" } `  | Export-Csv $tempfile -NoTypeInformation
Import-Csv $tempfile `  | ? { $hostname -notcontains $_."Hostname" } `  | Export-Csv $file -NoTypeInformation
$csvimport = @(Import-CSV $file)
$csvimport + $csv | export-csv "$file" -Force
exit
}
 
if ($csvimport -Match $hostname -Match $user2 -Match $Project) {$pah = "Exists"} else {
$pah = "Does notexist"
Import-Csv $file `  | ? { $hostname -notcontains $_."Hostname" } `  | Export-Csv $tempfile -NoTypeInformation
Import-Csv $tempfile `  | ? { $hostname -notcontains $_."Hostname" } `  | Export-Csv $file -NoTypeInformation
$csvimport = @(Import-CSV $file)
$csvimport + $csv | export-csv "$file" -Force
exit
}
 
if ($csvimport -Match $hostname -Match $user2 -Match $Visual) {$viah = "Exists"} else {
$viah = "Does notexist"
Import-Csv $file `  | ? { $hostname -notcontains $_."Hostname" } `  | Export-Csv $tempfile -NoTypeInformation
Import-Csv $tempfile `  | ? { $hostname -notcontains $_."Hostname" } `  | Export-Csv $file -NoTypeInformation
$csvimport = @(Import-CSV $file)
$csvimport + $csv | export-csv "$file" -Force
exit
}
Remove-Item $tempfile