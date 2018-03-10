@if not defined debug echo off

del %~dps0\ps2Wiz.zip

"c:\Program Files\7-Zip\7z.exe" a -r %~dps0\ps2Wiz.zip %~dpnxs0 -xr!bin -xr!obj -xr!$tf PSTest*.ps1 Demo-*.ps1 *.cs *.resx *.manifest *.settings app.config *.ico *.csproj *.rtf PS2Wiz.ps1 PS2Wiz.cmd Test-AllExamples.cmd -x!%~nx0

