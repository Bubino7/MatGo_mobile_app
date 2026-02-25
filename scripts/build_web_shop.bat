@echo off
REM Build shop_app for /shop_app/. Output: deploy\shop_app\
cd /d "%~dp0\..\shop_app"
if not exist pubspec.yaml (echo Error: shop_app not created. Run "flutter create" in shop_app\ first. & exit /b 1)
call flutter build web --base-href "/shop_app/"
set OUT_DIR=%~dp0..\deploy\shop_app
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
rmdir /s /q "%OUT_DIR%" 2>nul
xcopy /e /i build\web "%OUT_DIR%"
echo Done: deploy\shop_app
cd /d "%~dp0\.."
