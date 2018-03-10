
#requires -version 4.0
#requires -runasadministrator

<#
.SYNOPSIS
Hyper-V Quick Starter program

.DESCRIPTION
Given a source *.iso image will auto mount and start the os locally in a Virtual Machine.

.LINK
http://ps2wiz.codeplex.com

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com) all rights reserved.
Microsoft Reciprocal License (Ms-RL) 
http://www.microsoft.com/en-us/openness/licenses.aspx

#>

[CmdletBinding()]
Param(
    [parameter(HelpMessage="Operating System Source, as WIM or ISO")]
    [System.IO.FileInfo] $SourceImageFile,

    [parameter(HelpMessage="Operating System Source index within WIM file")]
    [int] $ImageIndex = 0,

    [parameter(HelpMessage="Computer Name (must be unique, use '*' for Random)")]
    [string] $ComputerName,

    [parameter(HelpMessage="Administrator Password (not encrypted).")]
    [string] $AdministratorPassword,

    [parameter(HelpMessage="Memory size allocated to the Virtual Machine")]
    [int64] $MemoryStartupBytes = 2GB,

    [parameter(HelpMessage="Hyper-V Client Generation")]
    [int] $Generation = 2,

    [parameter(HelpMessage="Name of the Virtual Switch")]
    [string] $SwitchName,

    [switch] $EULAApprove
)


######################################################################
##
##   Sub Routines ...
##
######################################################################

function Display-HyperLink( $Name, $Link, $Arguments = "" )
{
    if( $Host.Name -eq "PowershellWizardHost" )
    {
        [PowerShell_Wizard_Host.PSHostCallBack]::DisplayHyperLink($Name,$Link,$Arguments)
    }
}

######################################################################

<# 
.SYNOPSIS
Run a Console program Hidden and capture the output.

.PARAMETER
FilePath - Program Executable

.PARAMETER
ArgumentList - Array of arguments

.PARAMETER
RedirectStandardInput - text file for StdIn

.NOTES
Will output StdOut to Verbose.

#>
Function RunConsoleCommand 
(
    [string] $FilePath,
    [string[]] $ArgumentList,
    [string] $RedirectStandardInput
)
{

    $DiskPartOut = [System.IO.Path]::GetTempFileName()
    $DiskPartErr = [System.IO.Path]::GetTempFileName()

    $DiskPartOut, $DiskPartErr | write-verbose
    $ArgumentList | out-string |write-verbose

    $prog = start-process -WindowStyle Hidden -PassThru -RedirectStandardError $DiskPartErr -RedirectStandardOutput $DiskPartOut @PSBoundParameters

    $Prog.WaitForExit()

    get-content $DiskPartOut | Write-Verbose
    get-content $DiskPartErr | Write-Error

    $DiskPartOut, $DiskPartErr, $RedirectStandardInput | Remove-Item -ErrorAction SilentlyContinue

}

function RunDiskPartCmds ( [string[]] $DiskPartCommands )
{
    $DiskPartCmd = [System.IO.Path]::GetTempFileName()
    $DiskPartCommands | out-file -encoding ascii -FilePath $DiskPartCmd
    RunConsoleCommand -FilePath "DiskPart.exe" -RedirectStandardInput $DiskPartCmd
}

######################################################################

<# 
.SYNOPSIS
Get the Wim File ready for extraction

.PARAMETER
SourceImageFile - Source file (Either *.wim or *.iso). 

.NOTES
Will mount the *.iso image if required.

#>
function Get-WimData
(
    [parameter(Mandatory=$true,HelpMessage="Operating System Source, as WIM or ISO")]
    [System.IO.FileInfo] $SourceImageFile,
    [parameter(HelpMessage="Operating System Source index within WIM file")]
    [int] $ImageIndex = 0
)
{
    if ( $SourceImageFile.Extension -in ".iso",".img" )
    {

        Write-Verbose "DVD ISO processing..."
        if ((get-diskimage $SourceImageFile.FullName -erroraction silentlycontinue | Get-Volume) -isnot [object])
        {
            write-verbose "Mount DVD:  $($SourceImageFile.FullName)"
            mount-diskimage $SourceImageFile.FullName
        }

        $DVDDrive = Get-DiskImage $SourceImageFile.FullName | get-Volume
        $DVDDrive | out-string | write-verbose
        if ( $DVDDrive -isnot [Object] )
        { throw "Get-DiskImage Failed for $($SourceImageFile.FullName)" }

        $WimImage = "$($DVDDrive.DriveLetter)`:\sources\install.wim"
    }
    elseif ( $SourceImageFile.Extension -eq ".WIM" )
    {
        $WimImage = $SourceImageFile.FullName
    }

    if ( $ImageIndex -eq 0 )
    {
        Write-Verbose "Got image, now let's get the index $WimImage"
        $result = get-windowsimage -ImagePath $WimImage |Select-object ImageIndex,ImageSize,ImageName | out-GridView -PassThru
        if ( $result.ImageIndex-as [int] -is [int] ) { $ImageIndex = $result.ImageIndex}
    }

    $DetailedInfo = get-windowsimage -ImagePath $WimImage -Index $ImageIndex
    $DetailedInfo | out-string | write-verbose

    return $DetailedInfo

}

######################################################################

function new-DiskPartCmds
(
    [parameter(Mandatory=$true)]
    [ValidateRange(1,20)]
    [int] $DiskID,
    [ValidateRange(1,2)]
    [int]  $Generation = 2,
    [string] $System = 'S',
    [string] $Windows = 'W',
    [string] $WinRE,
    [string] $Recovery,
    [int]  $recoverysize = 8KB
)
{

<# 
We use diskpart for format the new VHD(x), rather than native powershell commands due to uEFI limitations in PowerShell
http://www.altaro.com/hyper-v/creating-generation-2-disk-powershell/
#>

    function Set-DriveLetter ( [string] $VOl )
    {
        if ( $Vol.length -eq 1 ) { Write-Output "assign letter=""$Vol""" }
        elseif ( $Vol.length -gt 1 -and ( test-path $VOl ) ) { Write-Output "assign mount=""$Vol""" }
        else { throw "Bad assignment of VOlume Drive Letter or Mount Point $Vol" }
    }
    
    $PartType = 'mbr'
    $ReType = 'set id=27'
    $SysType = 'primary'
    if ( $Generation -eq 2 )
    {
        $PartType = 'gpt'
        $ReType = 'set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"','gpt attributes=0x8000000000000001'
        $SysType = 'efi'
    }
    
    $DiskPartCmds = @( "list disk","select disk $DiskID","clean","convert $PartType" )
    if ( $WinRE )
    {
        $DiskPartCmds += "rem == Windows RE tools partition ============"
        $DiskPartCmds += "create partition primary size=350",'format quick fs=ntfs label="Windows RE tools"'
        $DiskPartCmds += Set-DriveLetter $WinRE
        $DiskPartCmds += $ReType
    }

    $DiskPartCmds += "rem == System partition ======================"
    $DiskPartCmds += "create partition $SysType size=350", 'format quick fs=fat32 label="System"'
    $DiskPartCmds += Set-DriveLetter $System
    if ( $Generation -ne 2 ) 
    {
        $DiskPartCmds += "active"
    }
    else
    {
        $DiskPartCmds += "rem == Microsoft Reserved (MSR) partition ====","create partition msr size=128"
    }
    
    $DiskPartCmds += "rem == Windows partition ====================="
    $DiskPartCmds += "create partition primary"

    $DiskPartCmds += "rem == Create space for the recovery image ==="
    if ($RecoveryLetter) { $DiskPartCmds += "shrink minimum=$recoverysize" }

    $DiskPartCmds += "format quick fs=ntfs label=""Windows""" 
    if ( $Windows.Length -eq 1 ) { $DiskPartCmds += "assign letter=""$Windows""" } 
    if ( $Windows.Length -gt 1 -and ( test-path $Windows ) ) { $DiskPartCmds += "assign mount=""$Windows""" }

    if ( $Recovery )
    {
        $DiskPartCmds += "rem == Recovery image partition =============="
        $DiskPartCmds += "create partition primary",'format quick fs=ntfs label="Recovery image"'
        $DiskPartCmds += Set-DriveLetter $Recovery
        $DiskPartCmds += $ReType
    }

    $DiskPartCmds += "list volume","exit" 
    $DiskPartCmd = [System.IO.Path]::GetTempFileName()
    $DiskPartCmds | write-verbose
    $DiskPartCmds | out-file -encoding ascii -FilePath $DiskPartCmd
    RunConsoleCommand -FilePath "DiskPart.exe" -RedirectStandardInput $DiskPartCmd
}

<# 
.SYNOPSIS
Create a VHD File

.PARAMETER
VHDFile - Name of the VHD File to create.

.OUTPUTS
Returns a custom object of the drives created.

.NOTES
Can create a Gen 1 or Gen 2 computer 

#>
Function Prepare-VHDFile
(
    [parameter(Mandatory=$True,HelpMessage="Name of the Target VHD(x) file")]
    [string] $VHDFile, 

    [parameter(HelpMessage="Hyper-V Client Generation")]
    [int] $Generation = 2
)
{

    write-Verbose "Cleanup First..."
    if ( test-path $VHDFile ) 
    {
        dismount-vhd -Path $VHDFile -erroraction SilentlyContinue |out-null
        remove-item $VHDFile -confirm -force |out-null  
    }

    Write-Verbose "New VHD: $VHDFile"
    $Mount = New-VHD -Path $VHDFile -Dynamic -SizeBytes 30GB | Mount-VHD -PassThru
    $MOunt | out-string |write-verbose

    $Available = Get-ChildItem function:[F-Z]: -n | ? {([IO.DriveInfo] $_).DriveType -eq 'noRootdirectory' }
    $Windows = $Available[1]
    if ( $Experimental )
    {
        # When Creating and formatting a new drive on Windows 8.1, the autorun feature of Windows Explorer
        # will open a new explorer window. To avoid this, we will mount the new Windows volume to a path instead.
        $Windows = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName()
        MkDir -Path $Windows -Force | out-null
    }

    Write-Verbose "initialize-disk Generation($Generation)  $($mount.DiskNUmber)"
    New-DiskPartCmds -DiskID $($mount.DiskNUmber) -Generation $Generation -System $Available[0][0] -Windows $Windows[0] # !$Experimental
    
    Write-Verbose "Get the partition objects again so we can get the updated drive letters"
    return [PSCustomObject]@{ SystemPartition = $Available[0] ; OSPartition = $Windows } 

}

######################################################################

<# 
.SYNOPSIS
Construct the UNattend.xml file

.PARAMETER
<Various>

.OUTPUTS
REturns the string of the Unattend.xml file

#>

function Get-Unattend
(
    [object] $DetailedInfo,
    [string] $ComputerName,
    [SecureString] $AdministratorPassword,
    [string] $OutputFile,
    [Parameter(ValueFromRemainingArguments=$true)]$remainingArgs
)
{

<#

This Unattend.xml file is designed to auto-login to the local administrator account. 
Allowing for a quick and easy way to boot into the OS. 
Tested with Win 7,8.1,10,2008R2,2012R2,10Srv

#>

    write-Verbose "Parse the Version info for special cases...  $JoinADomain $($DetailedInfo.Version) $($DetailedInfo.InstallationType)"

    if ( [version]$detailedinfo.version -gt [version]"6.2.0.0" )
    {
        $OOBEBlock = "<HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><HideLocalAccountScreen>true</HideLocalAccountScreen>"
    }

    switch ( $DetailedInfo.InstallationType.Contains("Server").ToString() + " " + $DetailedInfo.Version.SubString(0,3) )
    {
        "True 6.4" { $ProducKey = "<ProductKey>JGNV3-YDJ66-HJMJP-KVRXG-PDGDH</ProductKey>" }
        # "False 10." { $ProducKey = "<ProductKey>6P99N-YF42M-TPGBG-9VMJP-YKHCF</ProductKey>" }
    }

    if ( $DetailedInfo.Architecture -eq 9 ) { $Architecture = "amd64" } else { $Architecture = "x86" }

@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Description>disable user account page</Description>
                    <Order>2</Order>
                    <Path>reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Setup\OOBE /v UnattendCreatedUser /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" >
            <RegisteredOrganization>Windows</RegisteredOrganization>
            <RegisteredOwner>Windows</RegisteredOwner>
            <TimeZone>$([System.Timezone]::CurrentTimezone.StandardName)</TimeZone>
            <ComputerName>$ComputerName</ComputerName>
            $ProducKey
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <NetworkLocation>Other</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
                $OOBEBlock
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( $AdministratorPassword )))</Value>
                </AdministratorPassword>
            </UserAccounts>
            <AutoLogon>
                <Enabled>true</Enabled>
                <Username>Administrator</Username>
                <Domain>.</Domain>
                <Password>
                    <Value>$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( $AdministratorPassword )))</Value>
                </Password>
                <LogonCount>1</LogonCount>
            </AutoLogon>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>cmd.exe /c shutdown -s -f -t 0</CommandLine>
                    <Description>Testing tools</Description>
                    <Order>1</Order>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" >
            <InputLocale>$((Get-WinUserLanguageList).InputMethodTips)</InputLocale>
            <SystemLocale>$((Get-WinUserLanguageList).LanguageTag)</SystemLocale>
            <UILanguage>$((Get-WinUserLanguageList).LanguageTag)</UILanguage>
            <UserLocale>$((Get-WinUserLanguageList).LanguageTag)</UserLocale>
        </component>
    </settings>
</unattend>
"@ | %{ $_.Replace("processorArchitecture=""amd64""","processorArchitecture=""$Architecture""") } | out-file -encoding ascii -FilePath $OutputFile

}


######################################################################
##
##   Main Processing
##
######################################################################

<# 
.SYNOPSIS
Main processing routine

.NOTES
We seperate the processing into this sub-routine in order to force paramater prompting later in the program.

#>

Function Main
(
    [parameter(Mandatory=$true,HelpMessage="Operating System Source, as WIM or ISO")]
    [System.IO.FileInfo] $SourceImageFile,

    [parameter(HelpMessage="Operating System Source index within WIM file")]
    [int] $ImageIndex = 0,

    [parameter(HelpMessage="Hyper-V Client Generation")]
    [int] $Generation = 2,

    [parameter(Mandatory=$true,HelpMessage="Computer Name (must be unique, use '*' for Random)")]
    [ValidatePattern("^\*$|^[a-zA-Z0-9][a-zA-Z0-9\-]{0,13}[a-zA-Z0-9]$")]
    [string] $ComputerName,

    [parameter(Mandatory=$true,HelpMessage="Administrator Password (not encrypted).")]
    [SecureString] $AdministratorPassword,

    [Parameter(ValueFromRemainingArguments = $true)]$remainingArgs
)
{

    Write-Verbose "Verify Computer Name:"
    if ( $ComputerName -eq "*")
    {
        $ComputerName = "VM-{0:x0}" -f (get-random)
    }

    if ( (get-vm -name $ComputerName -ErrorAction SilentlyContinue) -is [object] )
    {
        throw "Computername: $ComputerName is allready in use by Hyper-V"
    }

    #############################

    $VMSwitch = Get-VMSwitch | select-object -first 1
    if ( (get-vmswitch |measure).count -gt 1 ) 
    {
        $host.ui.RawUI.WindowTitle = "Get Switch"

        if( $Host.Name -eq "PowershellWizardHost" ) { Clear-Host }
        Write-Host "Virtual Machine will require at least one Virtual Switch."
        $VMSwitch = Get-VMSwitch | out-GridView -passthru

    }

    #############################
    $host.ui.RawUI.WindowTitle = "Export Source"

    $DetailedInfo = Get-WimData -SourceImageFile $SourceImageFile -ImageIndex $ImageIndex

    #############################

    $host.ui.RawUI.WindowTitle = "Create VHD Container"

    $VhdFile = ( Join-Path (get-vmhost).VirtualHardDiskPath "$ComputerName.Vhdx" )
    if ( $DetailedInfo.Architecture -eq 0 -or $DetailedInfo.Architecture -eq "x86" ) { $Generation = 1} 
    if ( [Version]$DetailedInfo.Version -lt [Version]"6.2.0.0" )  { $Generation = 1}
    $MountedDrives = Prepare-VHDFile -VHDFile $VhdFile -Generation $Generation

    #############################

    $host.ui.RawUI.WindowTitle = "Apply Image to VHD"
    Write-Host "Applying Image..."
    if( $Host.Name -eq "PowershellWizardHost" )
    {
        [PowerShell_Wizard_Host.PSHostCallBack]::DisplayImage( "http://blogs.msdn.com/cfs-filesystemfile.ashx/__key/communityserver-blogs-components-weblogfiles/00-00-01-38-53-metablogapi/1261.progress_5F00_7A4A65F2.gif")
    }

    if ( ! ( test-path "$($MountedDrives.OSPartition)\windows\System32\NTOSKRNL.exe" ) ) 
    {
        Write-Verbose "Apply the Image $($DetailedInfo.ImagePath) to $($MountedDrives.OSPartition)   $($DetailedInfo.ImageIndex)"
        Expand-WindowsImage -ImagePath $($DetailedInfo.ImagePath) -ApplyPath $MountedDrives.OSPartition -Index $($DetailedInfo.ImageIndex) -confirm -LogPath ([System.IO.Path]::GetTempFileName())
    }

    # We may need to remap some of the boot entries if the Operating System Volume was mounted to a folder rather than a drive letter.
    Write-Verbose "Apply the boot files to: $($MountedDrives.SystemPartition)"
    $BCDArgs = "$($MountedDrives.OSPartition)\windows","/s",$MountedDrives.SystemPartition
    if ( $Generation -eq 2 ) 
    { 
        RunConsoleCommand -FilePath "BCDBoot.exe" -ArgumentList $BCDArgs, "/F","ALL" 
        $BCDPath = "$($MountedDrives.SystemPartition)\EFI\Microsoft\Boot\bcd"
    } 
    else 
    { 
        RunConsoleCommand -FilePath "BCDBoot.exe" -ArgumentList $BCDArgs, "/F","BIOS" 
        $BCDPath = "$($MountedDrives.SystemPartition)\boot\bcd"
    }

    if ( $Experimental ) 
    {
        RunConsoleCommand -FilePath "bcdedit.exe" -ArgumentList "/store",$BCDPath,"/enum","all"
        RunConsoleCommand -FilePath "bcdedit.exe" -ArgumentList "/store",$BCDPath,"/set","{default}","systemroot","\windows"
        RunConsoleCommand -FilePath "bcdedit.exe" -ArgumentList "/store",$BCDPath,"/set","{default}","device","partition=\Device\HarddiskVolume3"
        RunConsoleCommand -FilePath "bcdedit.exe" -ArgumentList "/store",$BCDPath,"/set","{default}","osdevice","partition=\Device\HarddiskVolume3"
        RunConsoleCommand -FilePath "bcdedit.exe" -ArgumentList "/store",$BCDPath,"/set","{default}","path","\windows\system32\winload.exe"
        RunConsoleCommand -FilePath "bcdedit.exe" -ArgumentList "/store",$BCDPath,"/enum","all"
    }

    #############################

    $host.ui.RawUI.WindowTitle = "Create Unattend"
    if( $Host.Name -eq "PowershellWizardHost" ) { Clear-Host }
    Write-Host "Gather Additional Parameters needed for Virtual Machine."

    $MyUnattend = Get-Unattend -DetailedInfo $DetailedInfo @PSBoundParameters -OutputFile "$($MountedDrives.OSPartition)\Windows\system32\sysprep\Unattend.xml"

    #############################

    write-verbose "Cleanup ISO Image: $ISOImage"
    if ( $SourceImageFile.Extension -in ".iso",".img" )
    {
        Dismount-DiskImage -ImagePath $SourceImageFile.FullName
    }

    dismount-Vhd -path $VHDFile

    #############################
    $host.ui.RawUI.WindowTitle = "Start Virtual Machine"

    $VM = new-vm -name $ComputerName -MemoryStartupBytes $MemoryStartupBytes -VHDPath $VhdFile -Generation $Generation -SwitchName $VMSwitch.Name
    Start-VM $VM

    #############################
    $host.ui.RawUI.WindowTitle = "Finished"
    
    Write-Host "Virtual Machine has started."

    Display-HyperLink "Launch Hyper-V Client" "VMConnect.exe" "$Env:ComputerName ""$ComputerName"" -G $($VM.ID) -C 0"

}


######################################################################
##
##   Verification 
##
######################################################################

Write-Verbose "Verify Hyper-V is present"
if ( (get-command get-vmhost -erroraction silentlycontinue) -isnot [object] )
{
    Write-Host "Hyper-V must be enabled."
    if( (gwmi win32_operatingsystem).producttype -ne 1 )
    {
        write-verbose "Server"
        Display-HyperLink "Launch Server Manager" "ServerManager.exe"
    }
    else
    {
        Display-HyperLink "Launch Server Manager" "optionalfeatures.exe"
    }
    throw [System.PlatformNotSupportedException]"Missing Hyper-V"
}

###################

Write-Verbose "Check for at least one switch..."
if ( (get-vmswitch | measure-object).Count -eq 0 )
{
    Write-Host "Create at least one Virtual Switch in Hyper-V"
    Display-HyperLink "Launch Hyper-V Console" "VirtMgmt.msc"
    throw [System.PlatformNotSupportedException]"Missing Hyper-V tool VirtMgmt.msc"
}

###################

Write-Verbose "Verify Disk Free Space"
if ( (get-volume (get-vmhost).VirtualHardDiskPath[0]).SizeRemaining -lt 8gb )
{
    Write-Host "Require at least 8GB of free space on drive $((get-vmhost).VirtualHardDiskPath)"
    Write-Host "You may change the default Virtual Hard Disk Target in the Hyper-V Console."
    throw [System.PlatformNotSupportedException]"Requires 8gb of free space"
}

###################

Write-Verbose "Verify Free Memory"

if ( (gwmi win32_operatingsystem).TotalVisibleMemorySize *1024 -lt 3.5gb )
{
    throw [System.InsufficientMemoryException]"Requires 3.5GB free memory"
}

write-Verbose "Pass System Checks.. continue with installation"


###################

if ( ! $EULAApprove ) 
{
    $host.ui.RawUI.WindowTitle = "License"
    if( $Host.Name -eq "PowershellWizardHost" )
    {
        $RTFString = [PowerShell_Wizard_Host.PSHostCallBack]::GetFileFromResource("MS-RL.rtf")
        [PowerShell_Wizard_Host.PSHostCallBack]::DisplayRTF($RTFString)
        [PowerShell_Wizard_Host.PSHostCallBack]::WaitForNext()
    }

}

################
$host.ui.RawUI.WindowTitle = "Gather"
# Clear-Host
Write-Host "Virtual Machine will need a source image, and a target Comptuer Name."

# Convert the Administrator Password as a argument from a String to SecureString
if( $PSBoundParameters.ContainsKey("AdministratorPassword"))
{
    $PSBoundParameters.ITem("AdministratorPassword") = $PSBoundParameters.ITem("AdministratorPassword") | ConvertTo-SecureString -ASPlainText -Force
}

Main @PSBoundParameters
