@echo off
REM Build admin app for /admin/. Output: deploy\admin\
cd /d "%~dp0\..\admin_shop_app"
if not exist pubspec.yaml (echo Error: admin_shop_app not created. Run "flutter create" in admin_shop_app\ first. & exit /b 1)
call flutter build web --base-href "/admin/"
set OUT_DIR=%~dp0..\deploy\admin
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
rmdir /s /q "%OUT_DIR%" 2>nul
xcopy /e /i build\web "%OUT_DIR%"
echo Done: deploy\admin
cd /d "%~dp0\.."
