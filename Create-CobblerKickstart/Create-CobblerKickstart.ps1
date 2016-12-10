 <# 
    .SYNOPSIS
	Create Cobbler Kickstart command from XLSX import - used to kick off linux builds using cobbler kickstart config file.

    .NOTES 
     NAME: Get-EmployeeIDFromUser.ps1
	 VERSION: 1.0
     AUTHOR: Daniel Tsekhanskiy
     LASTEDIT: 12/6/2015
#>

#Declare the file path and sheet name
$file = "H:\Programs\Scripts\CobblerKickstart.xlsx"
$sheetName = "Sheet1"

#Create an instance of Excel.Application and Open Excel file
$objExcel = New-Object -ComObject Excel.Application
$workbook = $objExcel.Workbooks.Open($file)
$sheet = $workbook.Worksheets.Item($sheetName)
$objExcel.Visible=$false

#Count max row
$rowMax = 2#($sheet.UsedRange.Rows).count 

#Declare the starting positions
$row1,$col1 = 1,1
$row2,$col2 = 1,2
$row3,$col3 = 1,3
$row4,$col4 = 1,4
$row5,$col5 = 1,5
$row6,$col6 = 1,6
$row7,$col7 = 1,7
$row8,$col8 = 1,8
$row9,$col9 = 1,9
$row10,$col10 = 1,10
$row11,$col11 = 1,11
$row12,$col12 = 1,12
$row13,$col13 = 1,13

#loop to get values and store it
for ($i=1; $i -le $rowMax-1; $i++)
{
$name = $sheet.Cells.Item($row1+$i,$col1).text 
$profile = $sheet.Cells.Item($row2+$i,$col2).text 
$MAC = $sheet.Cells.Item($row3+$i,$col3).text
$authdomain = $sheet.Cells.Item($row4+$i,$col4).text
$ip = $sheet.Cells.Item($row5+$i,$col5).text
$dc = $sheet.Cells.Item($row6+$i,$col6).text
$netmask = $sheet.Cells.Item($row7+$i,$col7).text
$domain = $sheet.Cells.Item($row8+$i,$col8).text
$gateway = $sheet.Cells.Item($row9+$i,$col9).text
$group = $sheet.Cells.Item($row10+$i,$col10).text
$nettype = $sheet.Cells.Item($row11+$i,$col11).text
$parttype = $sheet.Cells.Item($row12+$i,$col12).text
$rejectmask = $sheet.Cells.Item($row13+$i,$col13).text



Write-Host ("sudo cobbler system add --name=" +$name+ " --profile=" +$profile+ ".template --mac=" +$MAC+ " --ksmeta=""AUTHDOMAIN=" +$authdomain+ " BASEIP=" +$ip+ 
" BASENAMESERVER=" +$dc+ " BASENETMASK=" +$netmask+ " DOMAIN=" +$domain+ " GATEWAY=" +$gateway+ " HOSTNAMELONG=" +$name+"."+$domain+ " HOSTNAMESHORT=" +$name+
" LIKEWISEGROUP='" +$group+ "' NETWORKTYPE=" +$nettype+ " PARTITIONTYPE=" +$parttype+ " REJECTMASK=" +$rejectmask+ '"')

}
#close excel file
$objExcel.quit()