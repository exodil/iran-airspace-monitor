# Iran Airspace Monitor - Service Control Script
# Service'i yönetmek için kullan

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status", "logs")]
    [string]$Action
)

$TaskName = "IranAirspaceMonitor"

switch ($Action) {
    "start" {
        Write-Host "🚀 Service başlatılıyor..." -ForegroundColor Green
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep 3
        Write-Host "✅ Service başlatıldı!" -ForegroundColor Green
    }
    
    "stop" {
        Write-Host "🛑 Service durduruluyor..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TaskName
        Stop-Process -Name python -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Service durduruldu!" -ForegroundColor Green
    }
    
    "restart" {
        Write-Host "🔄 Service yeniden başlatılıyor..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TaskName
        Stop-Process -Name python -Force -ErrorAction SilentlyContinue
        Start-Sleep 2
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep 3
        Write-Host "✅ Service yeniden başlatıldı!" -ForegroundColor Green
    }
    
    "status" {
        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($Task) {
            Write-Host "📊 Service Durumu: $($Task.State)" -ForegroundColor Cyan
            
            # Python process kontrol
            $PythonProcess = Get-Process python -ErrorAction SilentlyContinue
            if ($PythonProcess) {
                Write-Host "✅ Python çalışıyor (PID: $($PythonProcess.Id))" -ForegroundColor Green
            } else {
                Write-Host "❌ Python çalışmıyor" -ForegroundColor Red
            }
            
            # Port kontrol
            $Port = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue
            if ($Port) {
                Write-Host "✅ Port 5000 aktif" -ForegroundColor Green
            } else {
                Write-Host "❌ Port 5000 kapalı" -ForegroundColor Red
            }
            
            # Web test
            try {
                $Response = Invoke-WebRequest http://localhost:5000 -UseBasicParsing -TimeoutSec 5
                Write-Host "✅ Web sitesi çalışıyor (Status: $($Response.StatusCode))" -ForegroundColor Green
            } catch {
                Write-Host "❌ Web sitesi erişilemiyor" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Service kurulu değil!" -ForegroundColor Red
        }
    }
    
    "logs" {
        Write-Host "📋 Son Python process'leri:" -ForegroundColor Cyan
        Get-Process python -ErrorAction SilentlyContinue | Format-Table
        
        Write-Host "📋 Port 5000 durumu:" -ForegroundColor Cyan
        Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue | Format-Table
        
        Write-Host "📋 Scheduled Task durumu:" -ForegroundColor Cyan
        Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue | Format-Table
    }
}

Write-Host "`n📋 Kullanım:" -ForegroundColor Yellow
Write-Host ".\service_control.ps1 start   - Service'i başlat" -ForegroundColor White
Write-Host ".\service_control.ps1 stop    - Service'i durdur" -ForegroundColor White
Write-Host ".\service_control.ps1 restart - Service'i yeniden başlat" -ForegroundColor White
Write-Host ".\service_control.ps1 status  - Service durumunu kontrol et" -ForegroundColor White
Write-Host ".\service_control.ps1 logs    - Log'ları göster" -ForegroundColor White 