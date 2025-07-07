@echo off
chcp 65001 >nul
echo 🚀 启动 Grocery Guardian 全栈应用...

REM 获取当前目录
set "PROJECT_ROOT=%~dp0"
echo 项目根目录: %PROJECT_ROOT%

REM 检查 MySQL 服务
echo 📊 检查 MySQL 服务...
sc query mysql | find "RUNNING" >nul
if %errorlevel% neq 0 (
    echo 启动 MySQL 服务...
    net start mysql
) else (
    echo MySQL 服务已在运行
)

REM 创建日志目录
if not exist "%PROJECT_ROOT%logs" (
    mkdir "%PROJECT_ROOT%logs"
)

REM 启动后端服务
echo 🔧 启动 Spring Boot 后端服务 (端口8080)...
cd /d "%PROJECT_ROOT%Backend"
start "" cmd /c mvn spring-boot:run > "%PROJECT_ROOT%logs\backend.log" 2>&1
echo 后端服务已启动

REM 等待后端服务启动
echo ⏳ 等待后端服务启动...
timeout /t 15 >nul

REM 启动推荐系统
echo 🤖 启动推荐系统服务 (端口8001)...
cd /d "%PROJECT_ROOT%Recommendation\src\main\java\org\recommendation\Rec_LLM_Module"

if not exist "venv\Scripts\activate.bat" (
    echo 🔧 推荐系统虚拟环境不存在，正在创建...
    python -m venv venv
    echo ✅ 推荐系统虚拟环境已创建
)

call venv\Scripts\activate.bat
start "" cmd /c python start_with_maven_db.py > "%PROJECT_ROOT%logs\recommendation.log" 2>&1
echo 推荐系统已启动

REM 启动 OCR 系统
echo 📷 启动 OCR 系统服务 (端口8000)...
cd /d "%PROJECT_ROOT%Ocr\src\main\java\org\ocr\python\demo"

if not exist "venv\Scripts\activate.bat" (
    echo 🔧 OCR 系统虚拟环境不存在，正在创建...
    python -m venv venv
    echo ✅ OCR 系统虚拟环境已创建
)

call venv\Scripts\activate.bat
start "" cmd /c uvicorn main:app --host 0.0.0.0 --port 8000 > "%PROJECT_ROOT%logs\ocr.log" 2>&1
echo OCR 系统已启动

REM 启动前端应用
echo 📱 启动 Flutter 前端应用...
cd /d "%PROJECT_ROOT%7.5-version-frontend\grocery_guardian_app"

REM 确保已经是一个 Flutter 项目
if not exist "pubspec.yaml" (
    echo ⚠️ 当前目录不是 Flutter 项目，正在创建...
    cmd /c flutter create .
)

start "" cmd /c flutter run -d chrome --web-port 3000 > "%PROJECT_ROOT%logs\frontend.log" 2>&1
echo Flutter 应用已启动

echo.
echo ✅ 所有服务已启动!
echo.
echo 📋 服务状态:
echo    🔧 后端服务: http://localhost:8080
echo    🤖 推荐系统: http://localhost:8001
echo    📷 OCR 系统: http://localhost:8000
echo    📱 Flutter 应用: http://localhost:3000
echo.
echo 📁 日志文件位置:
echo    backend.log: %PROJECT_ROOT%logs\backend.log
echo    recommendation.log: %PROJECT_ROOT%logs\recommendation.log
echo    ocr.log: %PROJECT_ROOT%logs\ocr.log
echo    frontend.log: %PROJECT_ROOT%logs\frontend.log
echo.
echo    停止所有服务: stop_all.bat

pause
