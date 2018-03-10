<#
# Example of how to prompt the user
# http://technet.microsoft.com/en-us/library/ff730939.aspx
#>

$Host.UI.RawUI.WindowTitle = "Prompt for Choice"

###################################


Write-Host "Manually construct some choices"


$title = "Delete Files"
$message = "Do you want to delete some files (not really, does nothing)?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Deletes all the files in the folder."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Retains all the files in the folder."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {"You selected Yes."}
        1 {"You selected No."}
    }


###################################

write-host "Powershell uses the PromptForChoice UI for -confirm actions"

copy c:\windows\system32\ntoskrnl.exe $env:temp -confirm

