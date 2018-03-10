<#
# Example of how to get-user input
#>

$Host.UI.RawUI.WindowTitle = "Read"

###################################

Write-Host "What is your Name:"
$User = REad-Host
Write-Host "Your name is $Value"

Write-Host "What is your Password:"
$Pass = REad-Host -ASSecureString
Write-Host "Your name is $Value"

$Cred = Get-Credential -Message "Time to enter some credentials" -USerName $User
Write-Host "USername is: $($Cred.UserName)"

WRite-Host "Press Any Key to Continue"
$host.ui.RawUI.ReadKey() | out-null
