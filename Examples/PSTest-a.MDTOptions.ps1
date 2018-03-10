
<#
# Example of how to enumerate through MDT functions
#>

cls

if ( $False )
{
	# This is a sample, do not run during normal tests...

	Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
	New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "C:\DeploymentShare" | out-null

	Select-MDTObject -FileType "Foo.exe" -RootNode "ds001:\Applications"
	Select-MDTObject -OutputMode Multiple -RootNode "ds001:\Applications"

}

