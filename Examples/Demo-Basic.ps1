
<#
.SYNOPSIS
Simple Demo Program

.LINK
http://ps2wiz.codeplex.com

.NOTES
Copyright Keith Garner (KeithGa@KeithGa.com) all rights reserved.
Microsoft Reciprocal License (Ms-RL) 
http://www.microsoft.com/en-us/openness/licenses.aspx

#>

[CmdletBinding()]
Param(
	[parameter(Mandatory=$False,HelpMessage="Source File")]
	[System.IO.FileInfo] $Path,

	[parameter(Mandatory=$False,HelpMessage="Destination Folder")]
	[System.IO.DirectoryInfo] $Destination
)

Write-Host "Hello World!"

Write-Host "What is your Name:"
$Name = Read-Host
Write-Host "Hello $Name"

$Cred = Get-Credential -UserName $Name -Message "Don't Enter Real Credentials"
write-Host "Hello $($Cred.UserName)"


#########################################


function Copy-MyItem
(
	[parameter(Mandatory=$true,HelpMessage="Source File")]
	[System.IO.FileInfo] $Path,

	[parameter(Mandatory=$true,HelpMessage="Destination Folder")]
	[System.IO.DirectoryInfo] $Destination
)
{
	write-Verbose "Copy $($Path.FUllName) to $($Destination.FullName)"
	copy-Item @PSBoundParameters -confirm
}

Write-Host "Copy a File..."

Copy-MyItem @PSBoundParameters

#########################################

Write-Host "Press Any Key To Continue..."
$host.ui.RawUI.ReadKey() | out-null

