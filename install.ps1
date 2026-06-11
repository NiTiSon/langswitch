# Define paths and URLs
$url = "https://github.com/NiTiSon/langswitch/releases/latest/download/langswitch.exe"
$installDir = "$env:LocalAppData\langswitch"
$exePath = "$installDir\langswitch.exe"
$startupFolder = "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = "$startupFolder\langswitch.lnk"
$uninstallScriptPath = "$installDir\uninstall.ps1"
$uninstallRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\langswitch"

# 1. Create installation directory
if (-not (Test-Path $installDir))
{
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

# 2. Remove previous version if exists
if (Test-Path $exePath)
{
    Write-Host "Removing previous version..." -ForegroundColor Yellow
    Remove-Item -Path $exePath -Force
}

# 3. Download the executable
Write-Host "Downloading langswitch.exe..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $url -OutFile $exePath

# 4. Create uninstall script
Write-Host "Creating uninstall script..." -ForegroundColor Cyan
@"
# langswitch uninstaller
`$process = Get-Process -Name "langswitch" -ErrorAction SilentlyContinue
if (`$process) { `$process | Stop-Process -Force }

`$startupFolder = "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup"
`$shortcutPath = "`$startupFolder\langswitch.lnk"
if (Test-Path `$shortcutPath) { Remove-Item -Path `$shortcutPath -Force }

`$installDir = "$env:LocalAppData\langswitch"
if (Test-Path `$installDir) { Remove-Item -Path `$installDir -Recurse -Force }

`$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\langswitch"
if (Test-Path `$regPath) { Remove-Item -Path `$regPath -Recurse -Force }

Write-Host "langswitch has been uninstalled." -ForegroundColor Green
"@ | Out-File -FilePath $uninstallScriptPath -Encoding utf8

# 5. Register in Windows Apps & Features
Write-Host "Registering application..." -ForegroundColor Cyan
$uninstallString = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$uninstallScriptPath`""
New-Item -Path $uninstallRegPath -Force | Out-Null
Set-ItemProperty -Path $uninstallRegPath -Name "DisplayName" -Value "LangSwitch"
Set-ItemProperty -Path $uninstallRegPath -Name "DisplayVersion" -Value "1.0.0"
Set-ItemProperty -Path $uninstallRegPath -Name "UninstallString" -Value $uninstallString
Set-ItemProperty -Path $uninstallRegPath -Name "DisplayIcon" -Value $exePath
Set-ItemProperty -Path $uninstallRegPath -Name "Publisher" -Value "NiTiSon"
Set-ItemProperty -Path $uninstallRegPath -Name "URLInfoAbout" -Value "https://github.com/NiTiSon/langswitch"
Set-ItemProperty -Path $uninstallRegPath -Name "NoModify" -Value 1
Set-ItemProperty -Path $uninstallRegPath -Name "NoRepair" -Value 1

# 6. Ask user about Administrator privileges
$title = "Privilege Settings"
$message = "Do you want this application to run with Administrator privileges at startup?`nThis is requirement to work in specific explorer windows"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Runs as admin."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Runs as normal user."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$result = $host.ui.PromptForChoice($title, $message, $options, 0)

# 7. Create startup shortcut
$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exePath
$shortcut.WorkingDirectory = $installDir
$shortcut.Save()

# 8. Apply Admin privilege flag if user selected 'Yes'
if ($result -eq 0)
{
    Write-Host "Applying Administrator privilege flag to shortcut..." -ForegroundColor Yellow
    # Byte 21 of a .lnk file controls the registry/run flags (0x20 enables Run as Admin)
    $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
    $bytes[21] = $bytes[21] -bor 0x20
    [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)
}

Write-Host "Installation completed successfully! Langswitch will work on next login." -ForegroundColor Green

# 9. Ask user about restarting the computer
$restartTitle = "Restart Computer"
$restartMessage = "Do you want to restart your computer now to apply the changes?"
$restartYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Restarts the computer now."
$restartNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "I will restart later."
$restartOptions = [System.Management.Automation.Host.ChoiceDescription[]]($restartYes, $restartNo)
$restartResult = $host.ui.PromptForChoice($restartTitle, $restartMessage, $restartOptions, 1)

if ($restartResult -eq 0)
{
    Write-Host "Restarting computer..." -ForegroundColor Yellow
    Restart-Computer -Confirm:$false
}