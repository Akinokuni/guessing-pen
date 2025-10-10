@echo off
REM PostgREST 测试脚本 (Windows)

echo.
echo ========================================
echo   测试 PostgREST 连接
echo ========================================
echo.

REM 停止旧容器
echo 停止旧的测试容器...
docker stop test-postgrest 2>nul
docker rm test-postgrest 2>nul

REM 启动测试容器
echo 启动 PostgREST 测试容器...
docker-compose -f docker-compose.test.yml up -d

REM 等待启动
echo 等待 PostgREST 启动...
timeout /t 10 /nobreak >nul

REM 检查状态
echo.
echo ========================================
echo 容器状态:
echo ========================================
docker ps | findstr test-postgrest

REM 查看日志
echo.
echo ========================================
echo PostgREST 日志:
echo ========================================
docker logs test-postgrest

REM 测试 API
echo.
echo ========================================
echo 测试 API:
echo ========================================
echo 测试根路径...
curl -s http://localhost:3001/

echo.
echo.
echo 测试表查询...
curl -s http://localhost:3001/players

echo.
echo.
echo ========================================
echo 测试完成
echo ========================================
echo.
echo 清理测试容器:
echo   docker-compose -f docker-compose.test.yml down
echo.
pause
