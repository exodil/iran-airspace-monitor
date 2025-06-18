# Iran Airspace Monitor - Port 80 Service Setup
# Bu script ile uygulama port 80'de surekli calisacak

Write-Host "Iran Airspace Monitor Port 80 Service Kuruluyor..." -ForegroundColor Green

# 1. Proje dizinine git
Set-Location C:\iran-airspace-monitor

# 2. Environment variables ayarla
$env:ADSENSE_CLIENT_ID="ca-pub-5789357886060337"
$env:FLASK_ENV="production"
$env:PORT="80"

# 3. Mevcut python process'leri durdur
Write-Host "Mevcut Python processleri durduruluyor..." -ForegroundColor Yellow
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force

# 4. Mevcut task varsa sil
$TaskName = "IranAirspaceMonitor"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# 5. Port 80 Task Scheduler ile service kur
$ScriptPath = "C:\iran-airspace-monitor\app.py"
$PythonPath = where.exe python
if (-not $PythonPath) {
    $PythonPath = "python"
}

# Yeni scheduled task olustur (Port 80)
$Action = New-ScheduledTaskAction -Execute $PythonPath -Argument $ScriptPath -WorkingDirectory "C:\iran-airspace-monitor"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Settings
$Settings = New-ScheduledTaskSettingsSet
$Settings.StartWhenAvailable = $true
$Settings.DontStopIfGoingOnBatteries = $true
$Settings.DontStopOnIdleEnd = $true

# Environment variables task'a ekle
$Env1 = New-ScheduledTaskEnvironmentVariable -Name "ADSENSE_CLIENT_ID" -Value "ca-pub-5789357886060337"
$Env2 = New-ScheduledTaskEnvironmentVariable -Name "PORT" -Value "80"
$Env3 = New-ScheduledTaskEnvironmentVariable -Name "FLASK_ENV" -Value "production"

# Task'i kaydet
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings

# 6. Firewall kurallari ekle
Write-Host "Firewall kurallari ekleniyor..." -ForegroundColor Green
New-NetFirewallRule -DisplayName "Iran Monitor HTTP 80" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Iran Monitor HTTPS 443" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue

# 7. Service'i baslat
Write-Host "Service baslatiliyor..." -ForegroundColor Green
Start-ScheduledTask -TaskName $TaskName

# 8. Status kontrol
Start-Sleep 5
$TaskInfo = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($TaskInfo) {
    Write-Host "Service Durumu: $($TaskInfo.State)" -ForegroundColor Green
} else {
    Write-Host "Service kurulumda sorun olustu!" -ForegroundColor Red
}

Write-Host "Setup tamamlandi!" -ForegroundColor Green
Write-Host "Site (Port 80): http://iranairspacemonitor.xyz" -ForegroundColor Cyan
Write-Host "Local test: http://localhost" -ForegroundColor Cyan
Write-Host "IP test: http://16.171.115.203" -ForegroundColor Cyan

Write-Host "ONEMLI: Cloudflare'de DNS Proxy'yi kapatin!" -ForegroundColor Yellow
Write-Host "Cloudflare DNS Records: A record - DNS only (gri bulut)" -ForegroundColor Yellow

# Test et
Write-Host "Test ediliyor..." -ForegroundColor Yellow
Start-Sleep 10
try {
    $Response = Invoke-WebRequest http://localhost -UseBasicParsing -TimeoutSec 15
    Write-Host "Site calisiyor! Status: $($Response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Site henuz baslamadi, 30 saniye bekleyin..." -ForegroundColor Yellow
} 