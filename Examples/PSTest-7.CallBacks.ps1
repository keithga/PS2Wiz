
<#
# Example of how to make custom calls back to the host.
#>

###############################################################

$RTFString = [PowerShell_Wizard_Host.PSHostCallBack]::GetFileFromResource("MS-RL.rtf")

if (!([string]::IsNullOrEmpty($RTFString)))
{
	Clear-Host
	Write-Host "Display the EULA"
	[PowerShell_Wizard_Host.PSHostCallBack]::DisplayRTF($RTFString)
	[PowerShell_Wizard_Host.PSHostCallBack]::WaitForNext()
}

######################################################################

Clear-Host 

write-host "Sometimes we may want to force the PowerShell Wizard Host to display things that are not typical"

write-host "Find the script directory"

$ScriptPath = Split-Path ([PowerShell_Wizard_Host.PSHostCallBack]::GetHostExe)

Write-Host "Local Path: $ScriptPath"

######################################################################

write-host "Display some fancy Graphics..."

$Animation = "http://blogs.msdn.com/cfs-filesystemfile.ashx/__key/communityserver-blogs-components-weblogfiles/00-00-01-38-53-metablogapi/1261.progress_5F00_7A4A65F2.gif"
[PowerShell_Wizard_Host.PSHostCallBack]::DisplayImage( $ANimation)

[PowerShell_Wizard_Host.PSHostCallBack]::DisplayHyperLink("Notepad","Notepad.exe","")
[PowerShell_Wizard_Host.PSHostCallBack]::DisplayHyperLink("CodePlex","http://www.codeplex.com","")

Write-Host "Press any key to continue..."
$host.ui.RawUI.ReadKey() | out-null

