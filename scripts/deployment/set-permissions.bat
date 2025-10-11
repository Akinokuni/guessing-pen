@echo off
REM 设置脚本执行权限的批处理文件
REM 在Windows环境下使用Git Bash设置Linux脚本权限

echo 正在设置脚本执行权限...

REM 检查是否安装了Git Bash
where bash >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: 未找到bash命令，请确保已安装Git for Windows
    echo 或者在WSL环境中运行此脚本
    pause
    exit /b 1
)

REM 使用Git Bash设置权限
bash -c "chmod +x scripts/deployment/acr-setup.sh"
bash -c "chmod +x scripts/deployment/acr-push.sh"
bash -c "chmod +x scripts/deployment/version-tag.sh"
bash -c "chmod +x scripts/deployment/image-info.sh"

echo 脚本权限设置完成！
echo.
echo 可执行的脚本:
echo   - scripts/deployment/acr-setup.sh      (ACR仓库设置)
echo   - scripts/deployment/acr-push.sh       (镜像推送)
echo   - scripts/deployment/version-tag.sh    (版本标签管理)
echo   - scripts/deployment/image-info.sh     (镜像信息查看)
echo.
echo 使用方法:
echo   bash scripts/deployment/acr-setup.sh --help
echo   bash scripts/deployment/acr-push.sh --help
echo.
pause