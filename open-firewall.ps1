#Requires -RunAsAdministrator
# HanaDesk Community Server - Windows 방화벽 규칙 추가
# 관리자 권한으로 실행해야 합니다.

$rules = @(
    @{ Name = "HanaDesk hbbs TCP 21115"; Port = 21115; Protocol = "TCP" }
    @{ Name = "HanaDesk hbbs TCP 21116"; Port = 21116; Protocol = "TCP" }
    @{ Name = "HanaDesk hbbs UDP 21116"; Port = 21116; Protocol = "UDP" }
    @{ Name = "HanaDesk hbbr TCP 21117"; Port = 21117; Protocol = "TCP" }
    @{ Name = "HanaDesk hbbs WS 21118";  Port = 21118; Protocol = "TCP" }
    @{ Name = "HanaDesk hbbr WS 21119";  Port = 21119; Protocol = "TCP" }
)

foreach ($r in $rules) {
    $existing = Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "[SKIP] $($r.Name) - already exists" -ForegroundColor Yellow
    } else {
        New-NetFirewallRule `
            -DisplayName $r.Name `
            -Direction Inbound `
            -Action Allow `
            -Protocol $r.Protocol `
            -LocalPort $r.Port `
            -Profile Any `
            -Description "HanaDesk Community Server" | Out-Null
        Write-Host "[OK]   $($r.Name)" -ForegroundColor Green
    }
}

Write-Host "`nFirewall rules configured." -ForegroundColor Cyan
