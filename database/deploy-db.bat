@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo 🗄️  开始部署数据库...

REM 数据库连接信息
set DB_HOST=pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com
set DB_PORT=5432
set DB_USER=aki
set DB_PASSWORD=20138990398QGL@gmailcom
set DB_NAME=postgres

REM 设置 PGPASSWORD 环境变量
set PGPASSWORD=%DB_PASSWORD%

echo 📋 检查数据库连接...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT version();" >nul 2>&1
if errorlevel 1 (
    echo ❌ 数据库连接失败，请检查连接信息
    pause
    exit /b 1
)
echo ✅ 数据库连接成功

echo 🔧 执行数据库初始化脚本...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f init.sql

if errorlevel 1 (
    echo ❌ 数据库初始化失败
    pause
    exit /b 1
)

echo ✅ 数据库初始化成功！
echo.
echo 📊 数据库信息:
echo   主机: %DB_HOST%
echo   端口: %DB_PORT%
echo   数据库: %DB_NAME%
echo   用户: %DB_USER%
echo.
echo 🔑 PostgREST 角色:
echo   匿名角色: web_anon
echo   认证角色: authenticator
echo.
echo 📝 创建的表:
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "\dt"
echo.
echo 👁️  创建的视图:
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "\dv"

REM 清除密码环境变量
set PGPASSWORD=

echo.
echo 🎉 数据库部署完成！
echo 现在可以启动 PostgREST 服务了

pause
