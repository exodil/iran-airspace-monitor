# Iran Airspace Monitor - Service Control Script
# Service'i yonetmek icin kullan

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status", "logs")]
    [string]$Action
)

$TaskName = "IranAirspaceMonitor"

switch ($Action) {
    "start" {
        Write-Host "Service baslatiliyor..." -ForegroundColor Green
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep 3
        Write-Host "Service baslatildi!" -ForegroundColor Green
    }
    
    "stop" {
        Write-Host "Service durduruluyor..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TaskName
        Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host "Service durduruldu!" -ForegroundColor Green
    }
    
    "restart" {
        Write-Host "Service yeniden baslatiliyor..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TaskName
        Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep 2
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep 3
        Write-Host "Service yeniden baslatildi!" -ForegroundColor Green
    }
    
    "status" {
        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($Task) {
            Write-Host "Service Durumu: $($Task.State)" -ForegroundColor Cyan
            
            # Python process kontrol
            $PythonProcess = Get-Process python -ErrorAction SilentlyContinue
            if ($PythonProcess) {
                Write-Host "Python calisiyor (PID: $($PythonProcess.Id))" -ForegroundColor Green
            } else {
                Write-Host "Python calismiyor" -ForegroundColor Red
            }
            
            # Port kontrol
            $Port = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue
            if ($Port) {
                Write-Host "Port 5000 aktif" -ForegroundColor Green
            } else {
                Write-Host "Port 5000 kapali" -ForegroundColor Red
            }
            
            # Web test
            try {
                $Response = Invoke-WebRequest http://localhost:5000 -UseBasicParsing -TimeoutSec 5
                Write-Host "Web sitesi calisiyor (Status: $($Response.StatusCode))" -ForegroundColor Green
            } catch {
                Write-Host "Web sitesi erisilemez" -ForegroundColor Red
            }
        } else {
            Write-Host "Service kurulu degil!" -ForegroundColor Red
        }
    }
    
    "logs" {
        Write-Host "Son Python processleri:" -ForegroundColor Cyan
        Get-Process python -ErrorAction SilentlyContinue | Format-Table
        
        Write-Host "Port 5000 durumu:" -ForegroundColor Cyan
        Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue | Format-Table
        
        Write-Host "Scheduled Task durumu:" -ForegroundColor Cyan
        Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue | Format-Table
    }
}

Write-Host ""
Write-Host "Kullanim:" -ForegroundColor Yellow
Write-Host ".\service_control_fixed.ps1 start   - Service'i baslat" -ForegroundColor White
Write-Host ".\service_control_fixed.ps1 stop    - Service'i durdur" -ForegroundColor White  
Write-Host ".\service_control_fixed.ps1 restart - Service'i yeniden baslat" -ForegroundColor White
Write-Host ".\service_control_fixed.ps1 status  - Service durumunu kontrol et" -ForegroundColor White
Write-Host ".\service_control_fixed.ps1 logs    - Loglari goster" -ForegroundColor White 