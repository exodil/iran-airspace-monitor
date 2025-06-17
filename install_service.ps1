# PowerShell Script to Install Iran Airspace Monitor as Windows Service
# Run as Administrator

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = "C:\iran-airspace-monitor",
    
    [Parameter(Mandatory=$false)]
    [string]$PythonPath = "C:\Python311\python.exe"
)

Write-Host "Installing Iran Airspace Monitor Service..." -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    exit 1
}

# Check if paths exist
if (-not (Test-Path $ProjectPath)) {
    Write-Host "Project path not found: $ProjectPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $PythonPath)) {
    Write-Host "Python path not found: $PythonPath" -ForegroundColor Red
    Write-Host "Please check your Python installation or update the PythonPath parameter" -ForegroundColor Yellow
    exit 1
}

try {
    # Create scheduled task
    $TaskName = "IranAirspaceMonitor"
    
    # Delete existing task if it exists
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Write-Host "Removing existing task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    # Create new task action
    $Action = New-ScheduledTaskAction -Execute $PythonPath -Argument "run_production.py" -WorkingDirectory $ProjectPath
    
    # Create trigger (start at boot)
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    
    # Create task settings
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Create principal (run as system)
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the task
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Iran Airspace Monitor - Real-time aircraft tracking service"
    
    Write-Host "Service installed successfully!" -ForegroundColor Green
    Write-Host "Task Name: $TaskName" -ForegroundColor Cyan
    Write-Host "To start the service now, run: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
    Write-Host "To check status, run: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
    
} catch {
    Write-Host "Error installing service: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Ask if user wants to start the service now
$StartNow = Read-Host "Start the service now? (y/n)"
if ($StartNow -eq "y" -or $StartNow -eq "Y") {
    try {
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "Service started successfully!" -ForegroundColor Green
        Write-Host "Check logs at: $ProjectPath\iran_airspace.log" -ForegroundColor Cyan
        Write-Host "Web interface will be available at: http://localhost:5000" -ForegroundColor Cyan
    } catch {
        Write-Host "Error starting service: $($_.Exception.Message)" -ForegroundColor Red
    }
} 