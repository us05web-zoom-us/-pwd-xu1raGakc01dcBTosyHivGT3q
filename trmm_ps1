# author: https://github.com/bradhawkins85
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

$innosetup = 'tacticalagent-v2.11.0-windows-amd64.exe'
$api = '"https://api.cacgreatchallange.org"'
$clientid = '1'
$siteid = '1'
$agenttype = '"server"'
$power = 0
$rdp = 0
$ping = 0
$auth = '"27757dd39574cf5d7ef03c0cbc099b9f0f91f754b23407450a751c0c68a20e3f"'
$downloadlink = 'https://github.com/amidaware/rmmagent/releases/download/v2.11.0/tacticalagent-v2.11.0-windows-amd64.exe'
$apilink = $downloadlink.split('/')

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$serviceName = 'tacticalrmm'
If (-not (Get-Service $serviceName -ErrorAction SilentlyContinue)) {
    $OutPath = $env:TMP
    $output = $innosetup

    $installArgs = @('-m install --api ', "$api", '--client-id', $clientid, '--site-id', $siteid, '--agent-type', "$agenttype", '--auth', "$auth")

    if ($power) { $installArgs += "--power" }
    if ($rdp) { $installArgs += "--rdp" }
    if ($ping) { $installArgs += "--ping" }

    Try {
        $DefenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue | Select-Object AntivirusEnabled
        if ($DefenderStatus -match "True") {
            Add-MpPreference -ExclusionPath 'C:\Program Files\TacticalAgent\*' -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath 'C:\Program Files\Mesh Agent\*' -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath 'C:\ProgramData\TacticalRMM\*' -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionProcess 'C:\Windows\Temp\is-*.tmp\tacticalagent*' -ErrorAction SilentlyContinue
        }
    } Catch { }

    $X = 0
    do {
        Start-Sleep -s 5
        $X += 1
    } until(($connectresult = Test-NetConnection $apilink[2] -Port 443 -WarningAction SilentlyContinue -InformationLevel Quiet) -or $X -eq 3)

    if ($connectresult -eq $true) {
        Try {
            Invoke-WebRequest -Uri $downloadlink -OutFile $OutPath\$output -UseBasicParsing
            Start-Process -FilePath $OutPath\$output -ArgumentList ('/VERYSILENT /SUPPRESSMSGBOXES /NORESTART') -WindowStyle Hidden -Wait
            Start-Sleep -s 7
            Start-Process -FilePath "C:\Program Files\TacticalAgent\tacticalrmm.exe" -ArgumentList $installArgs -WindowStyle Hidden -Wait
            Remove-Item -Path $OutPath\$output -ErrorAction SilentlyContinue
            exit 0
        } Catch {
            exit 1
        }
    } else {
        exit 1
    }
} else {
    exit 0
}
