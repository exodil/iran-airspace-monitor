# Iran Airspace Monitor - Windows Service Setup Script
# Bu script ile uygulama surekli calisacak

Write-Host "Iran Airspace Monitor Service Kuruluyor..." -ForegroundColor Green

# 1. Proje dizinine git
Set-Location C:\iran-airspace-monitor

# 2. Environment variables ayarla
$env:ADSENSE_CLIENT_ID="ca-pub-7341529817476662"
$env:FLASK_ENV="production"

# 3. Mevcut python process'leri durdur
Write-Host "Mevcut Python processleri durduruluyor..." -ForegroundColor Yellow
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force

# 4. Task Scheduler ile surekli calisan service kur
$TaskName = "IranAirspaceMonitor"
$ScriptPath = "C:\iran-airspace-monitor\app.py"

# Python path'i bul
$PythonPath = where.exe python
if (-not $PythonPath) {
    $PythonPath = "python"
}

# Mevcut task varsa sil
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Yeni scheduled task olustur
$Action = New-ScheduledTaskAction -Execute $PythonPath -Argument $ScriptPath -WorkingDirectory "C:\iran-airspace-monitor"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Settings - uyumlu parametreler
$Settings = New-ScheduledTaskSettingsSet
$Settings.StartWhenAvailable = $true
$Settings.DontStopIfGoingOnBatteries = $true
$Settings.DontStopOnIdleEnd = $true

# Task'i kaydet
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings

# 5. Service'i baslat
Write-Host "Service baslatiliyor..." -ForegroundColor Green
Start-ScheduledTask -TaskName $TaskName

# 6. Firewall kurali ekle
Write-Host "Firewall kurali ekleniyor..." -ForegroundColor Green
New-NetFirewallRule -DisplayName "Iran Airspace Monitor" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow -ErrorAction SilentlyContinue

# 7. Status kontrol
Start-Sleep 5
$TaskInfo = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($TaskInfo) {
    Write-Host "Service Durumu: $($TaskInfo.State)" -ForegroundColor Green
} else {
    Write-Host "Service kurulumda sorun olustu!" -ForegroundColor Red
}

Write-Host "Setup tamamlandi!" -ForegroundColor Green
Write-Host "Site: http://iranairspacemonitor.xyz" -ForegroundColor Cyan
Write-Host "Local test: http://localhost:5000" -ForegroundColor Cyan

# 8. Service kontrol komutlari
Write-Host "Service Kontrol Komutlari:" -ForegroundColor Yellow
Write-Host "Start-ScheduledTask -TaskName 'IranAirspaceMonitor'" -ForegroundColor White
Write-Host "Stop-ScheduledTask -TaskName 'IranAirspaceMonitor'" -ForegroundColor White
Write-Host "Get-ScheduledTask -TaskName 'IranAirspaceMonitor'" -ForegroundColor White

# 9. Test et
Write-Host "Test ediliyor..." -ForegroundColor Yellow
Start-Sleep 10
try {
    $Response = Invoke-WebRequest http://localhost:5000 -UseBasicParsing -TimeoutSec 15
    Write-Host "Site calisiyor! Status: $($Response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Site henuz baslamadi, 30 saniye bekleyin..." -ForegroundColor Yellow
    Write-Host "Manuel test: python app.py" -ForegroundColor Cyan
} 