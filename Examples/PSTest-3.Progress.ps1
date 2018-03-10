<#
# Example of how to display progress.
#>

$Host.UI.RawUI.WindowTitle = "Progress"

###################################

Write-Host "Downloading the Microsoft Deployment Toolkit..."
start-bitstransfer -Source http://download.microsoft.com/download/B/F/5/BF5DF779-ED74-4BEC-A07E-9EB25694C6BB/MicrosoftDeploymentToolkit2013_x64.msi -Destination $env:temp\MicrosoftDeploymentToolkit2013_x64.msi

remove-item $env:temp\MicrosoftDeploymentToolkit2013_x64.msi
Write-Host "Removed"

###################################

write-host "Start a sample progress going from 0% to 100%"

foreach ( $i in 1..20 )
{
	write-progress -ACtivity "Starting work $i" -percentcomplete ($i * 5)
	start-sleep -Milliseconds 100
}

start-sleep 2

write-host "The previous progress should still be visible on the screen"

write-host "Start a sample progress going from 0% to 100%, replacing the previous version"

foreach ( $i in 1..20 )
{
	write-progress -ACtivity "Working again $i" -percentcomplete ($i * 5)
	start-sleep -Milliseconds 100
}

write-host "The previous progress should still be visible on the screen"

start-sleep 2

write-host "Now, let's clear the progress on the screen..."

write-progress -Completed -Activity "Test"

write-host "Now, All Progress should be gone!"

start-sleep 2

write-host "Now, let's do some nested processing..."

for($i = 1; $i -lt 20; $i++ )
{
	write-progress -activity Updating -status 'Progress->' -percentcomplete ($i*5) -currentOperation OuterLoop;
	for($j = 1; $j -lt 20; $j++ )
	{
		write-progress -id  1 -activity Updating -status 'Progress' -percentcomplete ($j*5) -currentOperation InnerLoop
		start-sleep -milliseconds 1
	}
}

write-progress -Completed -id  1 -Activity "Test"
write-progress -Completed -Activity "Test"

start-sleep 2


