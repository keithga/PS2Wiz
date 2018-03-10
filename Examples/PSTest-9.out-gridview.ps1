
<#
# Example of how to make calls to Out-GridView
#>

cls

write-Host "Display a Dictionary Object"
out-gridview -wait -inputobject @{ FOo = "Cat"; Bar = "DOg" }

Write-Host "get-content as pipe"
get-content c:\windows\system.ini | out-gridview

Write-Host "get-content as argument (Will not display correctly in PowerShell.exe host."
out-gridview -InputObject (get-content c:\windows\system.ini) -wait

cls

write-host "Get-Process"
Get-Process | out-GridView

write-host "Get-Process Wait"
Get-Process | out-GridView -Wait

write-host "Get-Process PassThru (Select an object)"
Get-Process | out-GridView -PassThru

write-host "Get-Process Single with limited properties (Select an object)"
Get-Process | %{ New-Object PSObject -Property  @{ Name = $_.PRocessName; ID= $_.ID; Handles = $_.Handles  } } | out-GridView -OutputMode Single

write-host "Get-Process Multiple (Select some objects)"
Get-Process | out-GridView -OutputMode Multiple

