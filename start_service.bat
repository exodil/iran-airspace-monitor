@echo off
REM Start Iran Airspace Monitor on AWS EC2 Windows
REM Run this as Administrator

echo Starting Iran Airspace Monitor...
echo.

REM Change to project directory
cd /d "C:\iran-airspace-monitor"

REM Activate virtual environment if exists
if exist "venv\Scripts\activate.bat" (
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
)

REM Start the application
echo Starting Flask application...
python run_production.py

pause 