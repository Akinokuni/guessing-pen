@echo off
REM Docker 部署脚本 (Windows)
REM 用于快速部署猜猜笔挑战应用

echo.
echo ========================================
echo   Docker 部署脚本
echo ========================================
echo.

REM 检查 .env 文件
if not exist .env (
    echo [错误] .env 文件不存在
    echo 请先创建 .env 文件，可以从 .env.example 复制：
    echo   copy .env.example .env
    pause
    exit /b 1
)

echo [OK] 找到 .env 文件
echo.

REM 停止并删除旧容器
echo [步骤 1/4] 停止旧容器...
docker-compose -f docker-compose.prod.yml down 2>nul
echo [OK] 旧容器已停止
echo.

REM 构建镜像
echo [步骤 2/4] 构建 Docker 镜像...
docker-compose -f docker-compose.prod.yml build --no-cache
if errorlevel 1 (
    echo [错误] 镜像构建失败
    pause
    exit /b 1
)
echo [OK] 镜像构建完成
echo.

REM 启动容器
echo [步骤 3/4] 启动容器...
docker-compose -f docker-compose.prod.yml up -d
if errorlevel 1 (
    echo [错误] 容器启动失败
    pause
    exit /b 1
)
echo [OK] 容器启动成功
echo.

REM 等待服务启动
echo [步骤 4/4] 等待服务启动...
timeout /t 10 /nobreak >nul

REM 检查服务状态
echo.
echo 检查服务状态...
echo.

REM 检查 API 服务
curl -f http://localhost:3001/api/health >nul 2>&1
if errorlevel 1 (
    echo [警告] API 服务: 启动中或未响应
) else (
    echo [OK] API 服务: 运行中
)

REM 检查前端服务
curl -f http://localhost/ >nul 2>&1
if errorlevel 1 (
    echo [警告] 前端服务: 启动中或未响应
) else (
    echo [OK] 前端服务: 运行中
)

echo.
echo 容器状态:
docker-compose -f docker-compose.prod.yml ps

echo.
echo ========================================
echo   部署完成！
echo ========================================
echo.
echo 访问地址:
echo   - 前端: http://localhost
echo   - API:  http://localhost:3001
echo.
echo 查看日志:
echo   docker-compose -f docker-compose.prod.yml logs -f
echo.
echo 停止服务:
echo   docker-compose -f docker-compose.prod.yml down
echo.
pause
