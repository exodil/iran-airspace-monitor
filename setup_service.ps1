# Iran Airspace Monitor - Windows Service Setup Script
# Bu script ile uygulama sürekli çalışacak

Write-Host "🚀 Iran Airspace Monitor Service Kuruluyor..." -ForegroundColor Green

# 1. Proje dizinine git
cd C:\iran-airspace-monitor

# 2. Environment variables ayarla
$env:ADSENSE_CLIENT_ID="ca-pub-7341529817476662"
$env:FLASK_ENV="production"

# 3. Mevcut python process'leri durdur
Write-Host "Mevcut Python process'leri durduruluyor..." -ForegroundColor Yellow
Stop-Process -Name python -Force -ErrorAction SilentlyContinue

# 4. Task Scheduler ile sürekli çalışan service kur
$TaskName = "IranAirspaceMonitor"
$ScriptPath = "C:\iran-airspace-monitor\app.py"
$PythonPath = (Get-Command python).Source

# Mevcut task varsa sil
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Yeni scheduled task oluştur
$Action = New-ScheduledTaskAction -Execute $PythonPath -Argument $ScriptPath -WorkingDirectory "C:\iran-airspace-monitor"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnDemand -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -StartWhenAvailable

# Task'ı kaydet
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings

# 5. Service'i başlat
Write-Host "Service başlatılıyor..." -ForegroundColor Green
Start-ScheduledTask -TaskName $TaskName

# 6. Firewall kuralı ekle
Write-Host "Firewall kuralı ekleniyor..." -ForegroundColor Green
New-NetFirewallRule -DisplayName "Iran Airspace Monitor" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow -ErrorAction SilentlyContinue

# 7. Status kontrol
Start-Sleep 5
$TaskInfo = Get-ScheduledTask -TaskName $TaskName
Write-Host "Service Durumu: $($TaskInfo.State)" -ForegroundColor Green

Write-Host "✅ Setup tamamlandı!" -ForegroundColor Green
Write-Host "🌐 Site: http://iranairspacemonitor.xyz" -ForegroundColor Cyan
Write-Host "📊 Local test: http://localhost:5000" -ForegroundColor Cyan

# 8. Service kontrol komutları
Write-Host "`n📋 Service Kontrol Komutları:" -ForegroundColor Yellow
Write-Host "Start-ScheduledTask -TaskName 'IranAirspaceMonitor'" -ForegroundColor White
Write-Host "Stop-ScheduledTask -TaskName 'IranAirspaceMonitor'" -ForegroundColor White
Write-Host "Get-ScheduledTask -TaskName 'IranAirspaceMonitor'" -ForegroundColor White

# 9. Test et
Write-Host "`n🧪 Test ediliyor..." -ForegroundColor Yellow
try {
    $Response = Invoke-WebRequest http://localhost:5000 -UseBasicParsing -TimeoutSec 10
    Write-Host "✅ Site çalışıyor! Status: $($Response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Site henüz başlamadı, 30 saniye bekleyin..." -ForegroundColor Red
} 