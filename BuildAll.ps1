
# Build all the scripts in the Examples Directory.

& $PSScriptRoot\Build.ps1 -Resources $(get-childitem $PSScriptRoot\Examples\PSTest*) -OutputFolder $PSScriptRoot\Release\Test

& $PSScriptRoot\Build.ps1 -Resources $PSScriptRoot\Examples\Demo-Basic.ps1 -OutputFolder $PSScriptRoot\Release\Basic
& $PSScriptRoot\Build.ps1 -Resources $PSScriptRoot\Examples\Demo-Wrapper.ps1 -OutputFolder $PSScriptRoot\Release\Wrapper
& $PSScriptRoot\Build.ps1 -Resources $PSScriptRoot\Examples\Demo-Wrapper.ps1 -OutputFolder $PSScriptRoot\Release\WrapperAdmin -Admin
& $PSScriptRoot\Build.ps1 -Resources $PSScriptRoot\Examples\Demo-Wrapper.ps1 -OutputFolder $PSScriptRoot\Release\WrapperAdminx64 -Admin -CPUType x64
& $PSScriptRoot\Build.ps1 -Resources $PSScriptRoot\Examples\Demo-HyperVQuickStart.ps1 -OutputFolder $PSScriptRoot\Release\Demo-HyperVQuickStart -Admin

