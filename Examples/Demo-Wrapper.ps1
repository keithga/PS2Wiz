
<#
.SYNOPSIS
Simple wrapper around another script

.EXAMPLE
c:> & '.\Release\Wrapper-Admin-x64\PowerShell Wizard Host.exe' -command "copy-item c:\windows\notepad.exe c:\windows\MyEditor.exe -confirm"

.LINK
http://ps2wiz.codeplex.com

.NOTES
Copyright Keith Garner (KeithGa@KeithGa.com) all rights reserved.
Microsoft Reciprocal License (Ms-RL) 
http://www.microsoft.com/en-us/openness/licenses.aspx

#>

[cmdletbinding()]
param(
        [parameter(mandatory=$true, position=0, ValueFromRemainingArguments=$true)][string] $Command
)

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope Process

invoke-expression -Command $Command
