@echo off
REM Build driver_app for /driver_app/
REM Run from repo root. Output: deploy\driver_app\

cd /d "%~dp0\..\driver_app"
if not exist pubspec.yaml (echo Error: driver_app not created. Run "flutter create" in driver_app\ first. & exit /b 1)

call flutter build web --base-href "/driver_app/"
set OUT_DIR=%~dp0..\deploy\driver_app
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
rmdir /s /q "%OUT_DIR%" 2>nul
xcopy /e /i build\web "%OUT_DIR%"
echo Done: deploy\driver_app
cd /d "%~dp0\.."
