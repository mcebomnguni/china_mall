@echo off
echo ============================================
echo  China Mall - Web Server
echo ============================================
echo.
echo Starting server at http://localhost:8080
echo Open your browser to: http://localhost:8080
echo.
echo Press Ctrl+C to stop.
echo.
cd /d "%~dp0build\web"
python -m http.server 8080
pause
