@echo off
setlocal EnableDelayedExpansion
title CNC Nexus Launcher
color 0b

echo ==========================================
echo      INICIANDO CNC NEXUS SYSTEM...
echo ==========================================
echo.

set "APP_DIR=%~dp0"
set "TARGET_FILE=%APP_DIR%index.html"

:: 1. Buscar MS Edge (x86 - Ruta Estandar)
set "EDGE_PATH=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if exist "!EDGE_PATH!" (
    echo [INFO] Edge detectado en x86.
    start "" "!EDGE_PATH!" --app="file:///!TARGET_FILE!" --window-size=1200,800 --start-maximized
    goto :SUCCESS
)

:: 2. Buscar MS Edge (x64 - Ruta Estandar)
set "EDGE_PATH=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
if exist "!EDGE_PATH!" (
    echo [INFO] Edge detectado en Program Files.
    start "" "!EDGE_PATH!" --app="file:///!TARGET_FILE!" --window-size=1200,800 --start-maximized
    goto :SUCCESS
)

:: 3. Buscar Chrome (Alternativa)
set "CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
if exist "!CHROME_PATH!" (
    echo [INFO] Chrome detectado.
    start "" "!CHROME_PATH!" --app="file:///!TARGET_FILE!" --window-size=1200,800 --start-maximized
    goto :SUCCESS
)

set "CHROME_PATH=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if exist "!CHROME_PATH!" (
    echo [INFO] Chrome detectado en x86.
    start "" "!CHROME_PATH!" --app="file:///!TARGET_FILE!" --window-size=1200,800 --start-maximized
    goto :SUCCESS
)

:: Fallback: Abrir con el navegador por defecto (sin modo app)
echo [WARN] No se detecto navegador compatible para modo App.
echo [INFO] Abriendo en navegador predeterminado...
start "" "%TARGET_FILE%"

:SUCCESS
echo.
echo [OK] Sistema cargado.
timeout /t 3 >nul
exit
