
<#
# Example of how to prompt the user
# http://poshcode.org/608
#>

$Host.UI.RawUI.WindowTitle = "Prompt"

###################################


$fields = new-object "System.Collections.ObjectModel.Collection``1[[System.Management.Automation.Host.FieldDescription]]"

$f = New-Object System.Management.Automation.Host.FieldDescription "String Field"
$f.HelpMessage  = "This is the help for the first field"
$f.DefaultValue = "Field1"
$f.Label = "&Any Text"

$fields.Add($f)

$f = New-Object System.Management.Automation.Host.FieldDescription "Secure String"
$f.SetparameterType( [System.Security.SecureString] )
$f.HelpMessage  = "You will get a password input with **** instead of characters"
$f.DefaultValue = "Password"
$f.Label = "&Password"

$fields.Add($f)

$f = New-Object System.Management.Automation.Host.FieldDescription "Numeric Value"
$f.SetparameterType( [int] )
$f.DefaultValue = "42"
$f.HelpMessage  = "You need to type a number, or it will re-prompt"
$f.Label = "&Number"

$fields.Add($f)

$results = $Host.UI.Prompt( "Caption", "Message", $fields )

Write-Output $results

###################################

Write-Host "Powershell will also use the Prompt() function for filling out mandatory parameters"


Write-Host "LEt's call Get-WMIObject without any parameters ( go ahead and type in win32_computerSystem )"

(get-wmiobject).__Path


Function Test-Parameters
(
    [parameter(Mandatory=$true)]
    [Switch] $EnableWidgets = $false,
    [parameter(Mandatory=$true)]
    [string[]] $ComputerNames,
    [parameter(Mandatory=$true)]
    [PSCredential] $Credentials,
    [string] $OptionalValue
)
{
    foreach ($COmputer in $ComputerNames)
    {
        write-host "Widget Processing: $EnableWidgets $($Credentials.UserName)   $Computer"
    }
}

Write-Host "LEt's call Test-Parameters and see what parameters it requires "

Test-Parameters

Function Test-ParametersAdvanced
(
    [parameter(Mandatory=$true)]
    [System.IO.FileInfo] $File
)
{
   $File |fl |out-string
}

Test-ParametersAdvanced


###############################################################

@"
the PowerShell Wizard Host supports the following basic types:

System.String (of course)
System.SByte System.Byte System.Char
System.Decimal System.Double System.Single
System.Int16 System.Int32 System.Int64
System.UInt16 System.UInt32 System.UInt64 System.UIntPtr
System.DateTime System.Guid (will be parsed from a string to the correct object type)

Additionally, these types will be displayed as CheckBoxes:

System.Boolean
System.Management.Automation.SwitchParameter

These types will be displayed with password prompts 

System.Management.Automation.PSCredential
System.Security.SecureString

And as a bonus, these types will display a File and directory dialog.
System.IO.FileInfo
System.IO.DirectoryInfo

"@

WRite-Host "Press Any Key to Continue"
$host.ui.RawUI.ReadKey() | out-null

