<#

.SYNOPSIS
PowerShell to PSWHost

.DESCRIPTION
Build Tool.
Convers a stand alone powershell script to Windows EXE with user interface.

.NOTES
PSWHost - Copyright (KeithGa@KeithGa.com) all rights reserved.
Apache License 2.0

.PARAMETER Resources
List of resources to be embedded into the project. 
All *.ps1 files will be loaded up at run time. 

.PARAMETER OutputFolder
Where to place the EXE file when compiled. 
Otherwise set to BuildType (like release or debug)

.PARAMETER Target
Either Clean or Build, by default will perform clean then build.

.PARAMETER BuildType
Either Release or Debug

.PARAMETER CPUType
Either "Any CPU", x86 or x64. Defaults to "Any CPU"

.PARAMETER Admin
When enabled will add an application manifest forcing the app to run elevated.

#>


[CmdletBinding()]
Param(
    [string[]] $Resources,
    [string] $OutputFolder,

    [ValidateSet("Build", "Clean")]
    [string[]] $target = @("Clean","Build"),

    [ValidateSet("Release", "Debug")]
    [string] $BuildType = "Release",

    [ValidateSet("Any CPU", "x86", "x64")]
    [string] $CPUType = "AnyCPU",

    [switch] $Admin
)

$ErrorActionPreference = 'stop'

#####################################

[void][System.Reflection.Assembly]::Load('Microsoft.Build, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][System.Reflection.Assembly]::Load('Microsoft.Build.Engine, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')

#region Globals
#####################################

function ConvertTo-BuildGlobals {
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable] $Values
    )

    $globals = new-object "System.Collections.Generic.Dictionary``2[[System.String],[System.String]]"
    foreach ( $Key in $values.Keys ) {
        $globals.Add( $Key, $values[$key] )
    }
    $globals | Write-Output
}

#endregion

#region Main 
#####################################

$Globals = @{
    Configuration = $BuildType
    Platform = $CPUType
    PlatformTarget = $CPUType
    OutputPath = $( if ( $OutputFolder ) { $OutputFolder } else { "$PSScriptRoot\$BuildType" } ) 
    NoWin32Manifest = (-not $Admin.IsPresent).ToString()
    ApplicationManifest = $( if ($admin) { "$PSScriptRoot\PowerShell Wizard Host\App.Manifest" } else { "" } )
} | ConvertTo-BuildGlobals

$Project = New-Object Microsoft.Build.Evaluation.Project -ArgumentList ("$PSScriptRoot\PowerShell Wizard Host\PowerShell Wizard Host.csproj" ,$Globals,"4.0")

if ( $resources ) {
    write-verbose "Add $Resources to project"
    $RemoveMe = $Project.Items | where-object EvaluatedInclude -eq "PSScript.ps1"
    if ( $RemoveMe ) {
        $Project.RemoveItem( $RemoveMe ) | out-null
    }

    $Resources | foreach-Object { $Project.AddItem("embeddedresource",$_) | out-null }
}

$Logger = (new-Object Microsoft.Build.BuildEngine.ConsoleLogger) -as [Microsoft.Build.Framework.ILogger[]] 
$Project.Build($target,$Logger) | write-verbose

[Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.UnloadAllProjects()

#endregion


