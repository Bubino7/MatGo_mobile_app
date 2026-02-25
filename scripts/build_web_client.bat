@echo off
REM Build client app for deployment at /client_app/
REM Usage: scripts\build_web_client.bat
REM Output: deploy\client_app\

cd /d "%~dp0\..\client_app"

echo Building MatGo client app for /client_app/...
call flutter build web --base-href "/client_app/"

set OUT_DIR=%~dp0..\deploy\client_app
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
rmdir /s /q "%OUT_DIR%" 2>nul
xcopy /e /i build\web "%OUT_DIR%"

echo Done. Deploy contents of: deploy\client_app
echo   - Or run: firebase deploy --only hosting

cd /d "%~dp0\.."
