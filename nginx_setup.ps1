# Install and Configure Nginx for Iran Airspace Monitor
# Run as Administrator

Write-Host "Setting up Nginx reverse proxy..." -ForegroundColor Green

# Download Nginx for Windows
$nginxUrl = "http://nginx.org/download/nginx-1.24.0.zip"
$nginxZip = "C:\nginx.zip"
$nginxPath = "C:\nginx"

try {
    # Download Nginx
    Write-Host "Downloading Nginx..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $nginxUrl -OutFile $nginxZip
    
    # Extract Nginx
    Write-Host "Extracting Nginx..." -ForegroundColor Yellow
    Expand-Archive -Path $nginxZip -DestinationPath "C:\" -Force
    
    # Rename folder
    if (Test-Path "C:\nginx-1.24.0") {
        if (Test-Path $nginxPath) { Remove-Item $nginxPath -Recurse -Force }
        Rename-Item "C:\nginx-1.24.0" "nginx"
    }
    
    # Create nginx configuration
    $nginxConfig = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    # Iran Airspace Monitor Server
    server {
        listen       80;
        server_name  iranairspacemonitor.xyz www.iranairspacemonitor.xyz;

        # Proxy to Flask app
        location / {
            proxy_pass http://127.0.0.1:5000;
            proxy_set_header Host `$host;
            proxy_set_header X-Real-IP `$remote_addr;
            proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto `$scheme;
        }

        # WebSocket support for real-time updates
        location /ws {
            proxy_pass http://127.0.0.1:5000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade `$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host `$host;
        }
    }
}
"@

    # Write config file
    $nginxConfig | Out-File -FilePath "$nginxPath\conf\nginx.conf" -Encoding UTF8
    
    Write-Host "Nginx configured successfully!" -ForegroundColor Green
    
    # Create start script
    $startScript = @"
@echo off
cd /d C:\nginx
start nginx.exe
echo Nginx started successfully!
echo Iran Airspace Monitor is now available at http://iranairspacemonitor.xyz
pause
"@

    $startScript | Out-File -FilePath "C:\start_nginx.bat" -Encoding ASCII
    
    Write-Host "Created start script: C:\start_nginx.bat" -ForegroundColor Cyan
    
    # Ask to start nginx
    $startNow = Read-Host "Start Nginx now? (y/n)"
    if ($startNow -eq "y" -or $startNow -eq "Y") {
        Set-Location $nginxPath
        Start-Process "nginx.exe" -WindowStyle Hidden
        Write-Host "Nginx started successfully!" -ForegroundColor Green
        Write-Host "Your site is now available at: http://iranairspacemonitor.xyz" -ForegroundColor Cyan
    }
    
    # Cleanup
    Remove-Item $nginxZip -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "Error setting up Nginx: $($_.Exception.Message)" -ForegroundColor Red
} 