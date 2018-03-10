<#
# Example of how to write output to the host.
#>

$Host.UI.RawUI.WindowTitle = "Write"

###################################

$h = "Hello World!"

# Output to the pipeline

'Hello World!'
"Hello World!"
$h

# Output to Write-Host

Write-Host -NoNewline $h.split()[0]
Write-Host -NoNewline " "
Write-Host            $h.split()[-1]

# Colors

write-host "$h" -BackgroundColor White -ForegroundColor Red

foreach ( $FC in [System.Enum]::GetNames('System.ConsoleColor') )
{
    foreach ( $BC in [System.Enum]::GetNames('System.ConsoleColor') )
    {
        write-host "$h" -ForegroundColor $FC -BackgroundColor $BC
        start-sleep -Milliseconds 1
    }
}

Write-Host "That's a lot of text"

start-sleep 5

clear-host

write-host "screen should be cleared..."

#Other types of output

$SavedVerbose = $VerbosePreference
$VerbosePreference = "SilentlyContinue"
write-verbose "This message should not be written to the console $h"
$VerbosePreference = "Continue"
write-verbose $h
$VerbosePreference = $SavedVerbose


# Use $debugpreference to prevent Write-Debug from asking for user input.
$debugPreference = "COntinue"
WRite-Debug $h

Write-Warning $h

WRite-Error $h

start-sleep 2

