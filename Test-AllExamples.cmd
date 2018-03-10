@if not defined debug echo off

echo $Host.UI.RawUI.WindowTitle = "Hello World" > %temp%\PSTest-All.ps1

:: Concatenate all Tests into a single file.

for %%i in ( "%~dp0\Examples\PSTest-*.ps1" ) do (
copy %temp%\PSTest-All.ps1 + "%%i" %temp%\PSTest-All.ps1 > nul
echo ###################################################### >> %temp%\PSTest-All.ps1
)

call :BuildDemo %temp%\PSTest-All.ps1 -OutputFolder "%~dps0Release\Test"

call :BuildDemo "%~dp0\Examples\Demo-HyperVQuickStart.ps1" -OutputFolder "%~dps0Release\HyperV" -Admin
call :BuildDemo "%~dp0\Examples\Demo-Basic.ps1" -OutputFolder "%~dps0Release\Basic"

call :BuildDemo "%~dp0\Examples\demo-Wrapper.ps1" -OutputFolder "%~dps0Release\Wrapper-Basic"
call :BuildDemo "%~dp0\Examples\demo-Wrapper.ps1" -OutputFolder "%~dps0Release\Wrapper-Admin" -Admin
call :BuildDemo "%~dp0\Examples\demo-Wrapper.ps1" -OutputFolder "%~dps0Release\Wrapper-Admin-x64" -Admin -CPUType x64

goto :EOF

:BuildDemo
@Powershell -executionPolicy Unrestricted -File "%~dp0PS2Wiz.ps1" -verbose %*
@powershell -executionPolicy Unrestricted -File "%~dp0PS2Wiz.ps1" -verbose %1 -Target Clean
goto :EOF
