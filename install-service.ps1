#Requires -RunAsAdministrator
# HanaDesk Community Server - Install Windows services (using WinSW)
# Must be run as Administrator.
#
# hbbs.exe and hbbr.exe are console applications and cannot be registered
# as Windows services directly. WinSW wraps them as proper Windows services.
# If WinSW is not found, it will be downloaded automatically from GitHub.
#
# Usage:  .\install-service.ps1

. "$PSScriptRoot\service-common.ps1"

# --- Locate or download WinSW ---
function Get-WinSW {
    $winswExe = Join-Path $ServiceBase "WinSW.exe"
    if (Test-Path $winswExe) { return $winswExe }

    Write-Host "[INFO] Downloading WinSW..." -ForegroundColor Yellow
    $url = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe"
    Write-Host "       $url" -ForegroundColor Gray

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $winswExe -UseBasicParsing -TimeoutSec 60
        Write-Host "[OK]   WinSW downloaded" -ForegroundColor Green
        return $winswExe
    } catch {
        Write-Host "[ERROR] Failed to download WinSW: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "        Download manually from:" -ForegroundColor Yellow
        Write-Host "        $url" -ForegroundColor Yellow
        Write-Host "        Save as $winswExe" -ForegroundColor Yellow
        exit 1
    }
}

# --- Create WinSW XML config for a service ---
function Write-ServiceXml($svc) {
    $xmlPath = Join-Path $ServiceBase "$($svc.Name).xml"
    $logDir  = Join-Path $ServiceBase "logs"
    $exePath = Join-Path $ServiceBase $svc.Executable

    $xml = @"
<service>
  <id>$($svc.Name)</id>
  <name>$($svc.DisplayName)</name>
  <description>$($svc.Description)</description>
  <executable>$exePath</executable>
  <workingdirectory>$ServiceBase</workingdirectory>
  <logpath>$logDir</logpath>
  <log mode="append">
    <sizeThreshold>10240</sizeThreshold>
    <keepFiles>3</keepFiles>
  </log>
  <startmode>Automatic</startmode>
</service>
"@
    Set-Content -Path $xmlPath -Value $xml -Encoding UTF8
    return $xmlPath
}

# --- Setup WinSW wrapper exe for a service ---
function Initialize-ServiceExe($svc) {
    $svcExe = Join-Path $ServiceBase "$($svc.Name).exe"
    $winswExe = Join-Path $ServiceBase "WinSW.exe"
    if (!(Test-Path $svcExe)) {
        Copy-Item $winswExe $svcExe -Force
    }
    return $svcExe
}

# --- Code-sign an executable using signtool (same settings as build.bat) ---
function Protect-Executable($exePath) {
    # Check if already signed (works without signtool)
    $sig = Get-AuthenticodeSignature -FilePath $exePath -ErrorAction SilentlyContinue
    if ($sig -and $sig.Status -eq 'Valid') {
        Write-Host "[SIGN] $(Split-Path -Leaf $exePath) — already signed, skipping" -ForegroundColor Gray
        return $true
    }

    $signtool = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if (!$signtool) {
        Write-Host "[WARN] signtool.exe not found in PATH — skipping code signing for $(Split-Path -Leaf $exePath)" -ForegroundColor Yellow
        Write-Host "       Run from a Developer Command Prompt or add Windows SDK to PATH" -ForegroundColor Gray
        return $false
    }

    Write-Host "[SIGN] Signing $(Split-Path -Leaf $exePath)..." -ForegroundColor Gray
    $result = & signtool.exe sign /s my /tr http://timestamp.digicert.com /fd sha256 /td sha256 /a $exePath 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SIGN] $(Split-Path -Leaf $exePath) — signed" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[WARN] Code signing failed for $(Split-Path -Leaf $exePath)" -ForegroundColor Yellow
        Write-Host "       $result" -ForegroundColor Gray
        return $false
    }
}

# ============================================================

$winswExe = Get-WinSW
Write-Host "WinSW: $winswExe" -ForegroundColor Gray
Write-Host "=== HanaDesk Community Server - Install ===" -ForegroundColor Cyan
Write-Host "Base path: $ServiceBase" -ForegroundColor Gray

# Create logs directory
$logDir = Join-Path $ServiceBase "logs"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

foreach ($svc in $services) {
    $exePath = Join-Path $ServiceBase $svc.Executable
    if (!(Test-Path $exePath)) {
        Write-Host "[ERROR] $exePath not found" -ForegroundColor Red
        continue
    }

    # Remove existing service if any
    $existing = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($existing) {
        $svcExe = Join-Path $ServiceBase "$($svc.Name).exe"
        if (Test-Path $svcExe) {
            if ($existing.Status -eq 'Running') {
                & $svcExe stop | Out-Null
                Write-Host "[STOP] $($svc.Name)" -ForegroundColor Yellow
            }
            & $svcExe uninstall | Out-Null
            Start-Sleep -Seconds 1
        } else {
            sc.exe delete $svc.Name | Out-Null
            Start-Sleep -Seconds 1
        }
    }

    # Create XML config and wrapper exe
    Write-ServiceXml $svc | Out-Null
    $svcExe = Initialize-ServiceExe $svc

    # Code-sign the wrapper exe
    Protect-Executable $svcExe | Out-Null

    # Install and start
    & $svcExe install | Out-Null
    & $svcExe start | Out-Null
    Start-Sleep -Seconds 2

    $status = (Get-Service -Name $svc.Name -ErrorAction SilentlyContinue).Status
    if ($status -eq 'Running') {
        Write-Host "[OK]   $($svc.DisplayName) - $status" -ForegroundColor Green
    } else {
        Write-Host "[WARN] $($svc.DisplayName) - $status (check logs\ folder)" -ForegroundColor Yellow
    }
}

Write-Host "`nServices installed and started." -ForegroundColor Cyan
Write-Host "Ports: hbbs=21115-21116,21118 / hbbr=21117,21119" -ForegroundColor Gray
Write-Host "Logs:  $logDir\" -ForegroundColor Gray
