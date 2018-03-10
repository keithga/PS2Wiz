
<#
# Example of how to handle error cases...
#>

###############################################################

Function Can-Run ( $Message )
{
	$Prompts = @()
	$Prompts += New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Generate the error."
	$Prompts += New-Object System.Management.Automation.Host.ChoiceDescription "&no", "Skip over this test."

	$options = [System.Management.Automation.Host.ChoiceDescription[]] $Prompts
	return $host.ui.PromptForChoice("Prompt", $message, $options, 1) -eq 0
}


if ( can-Run "try catch" )
{
	try
	{
		100/0
	}
	catch
	{
		write-host "recovered from error"
	}
}

if ( Can-Run "Throw an error" )
{
	throw "This is an error that is thrown"
}


if ( Can-Run "Parameter Error" )
{
	Get-Item  $Null
}


if ( Can-Run "Runtime Error" )
{
	100 / 0
}

