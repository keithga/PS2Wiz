
<#

.SYNOPSIS
PowerShell to Powershell Wizard Host

.DESCRIPTION

Build Tool.
Convers a stand alone powershell script to Windows EXE with user interface.

.LINK
http://ps2wiz.codeplex.com

.NOTES
Copyright Keith Garner (KeithGa@KeithGa.com) all rights reserved.
Microsoft Reciprocal License (Ms-RL) 
http://www.microsoft.com/en-us/openness/licenses.aspx

#>


[CmdletBinding()]
Param(
	[parameter(Mandatory=$true)]
	[string] $InputFile,

	[ValidateSet("Build", "Clean")]
	[string] $target = "Build",
	[ValidateSet("Release", "Debug")]
	[string] $BuildType = "Release",
	[ValidateSet("Any CPU", "x86", "x64")]
	[string] $CPUType = "AnyCPU",
	[string] $OutputFolder = $null, 
	[switch] $Admin = $False
)

$ScriptDir = split-path -parent $MyInvocation.MyCommand.Definition
$Project = join-path -resolve $ScriptDir "Powershell Wizard Host\PowerShell Wizard Host.csproj"

foreach ( $File in $ScriptDir, $Project )
{
	if ( ! ( test-path $File ) )
	{
		throw "Missing project file: $File"
	}
}
write-verbose "Copy the Input File [$InputFile] locally..."
$PSScript = (join-path $ScriptDir "Powershell Wizard Host\PSScript.ps1")

copy-item -Path $InputFile -Destination $PSScript -Force

[void][System.Reflection.Assembly]::Load('Microsoft.Build.Engine, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][System.Reflection.Assembly]::Load('Microsoft.Build, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][System.Reflection.Assembly]::Load('mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')

$Logger = new-Object Microsoft.Build.BuildEngine.ConsoleLogger
$arraylog = New-Object collections.generic.list[Microsoft.Build.Framework.ILogger]
$arraylog.Add($Logger)

$globals = new-object "System.Collections.Generic.Dictionary``2[[System.String, mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089],[System.String, mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]]"
$globals.Add("Configuration",$BuildType)
$globals.Add("Platform",$CPUType)
$globals.Add("PlatformTarget",$CPUType)
if ( !$Admin )
{
	# Do not add the Application Manifest (required only for programs that must run elevated)
	$globals.Add("ApplicationManifest","")
	$globals.Add("NoWin32Manifest","False")
}

if ([string]::isNullOrEmpty($OutputFolder))
{
	$globals.Add("OutputPath",(join-path (split-path $MyInvocation.MyCommand.Definition) "$BuildType\$CPUType"))
}
else
{
	$globals.Add("OutputPath",$OutputFolder)
}


$params = new-object Microsoft.Build.Execution.BuildParameters
$params.DetailedSummary = $false
$params.DefaultToolsVersion = 4.0
$params.MaxNodeCount = 8
$params.BuildThreadPriority = "Highest"
$Params.GlobalProperties = $Globals
if ( $VerbosePreference -eq "Continue" )
{
	$params.Loggers=$arraylog
}

$request = new-object Microsoft.Build.Execution.BuildRequestData($Project, $globals, "4.0", @($target) , $null)
$manager = new-Object Microsoft.Build.Execution.BuildManager
write-verbose "start BUild"
$result = $manager.Build($params, $request) 
$result.ResultsByTarget[$target].Items | out-string | write-verbose

Write-verbose "Output the result:"
$result.ResultsByTarget[$target].Items.ItemSpec
