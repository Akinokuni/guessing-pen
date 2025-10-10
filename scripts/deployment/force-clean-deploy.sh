#!/bin/bash

# 强制清理并重新部署

echo "🔥 强制清理所有容器和端口..."
echo ""

# 1. 停止所有 Docker Compose 服务
echo "停止 docker-compose..."
docker-compose -f docker-compose.prod.yml down -v 2>/dev/null || true
docker-compose -f docker-compose.yml down -v 2>/dev/null || true

# 2. 强制停止所有相关容器
echo "强制停止所有容器..."
docker ps -a | grep guessing-pen | awk '{print $1}' | xargs -r docker stop 2>/dev/null || true
docker ps -a | grep guessing-pen | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

# 3. 查找并杀死占用 3001 端口的进程
echo "检查 3001 端口..."
PID=$(lsof -ti:3001 2>/dev/null || netstat -tlnp 2>/dev/null | grep :3001 | awk '{print $7}' | cut -d'/' -f1)
if [ ! -z "$PID" ]; then
    echo "杀死占用 3001 端口的进程: $PID"
    kill -9 $PID 2>/dev/null || true
fi

# 4. 查找并杀死占用 80 端口的进程（如果不是 nginx）
echo "检查 80 端口..."
PID=$(lsof -ti:80 2>/dev/null | head -1)
if [ ! -z "$PID" ]; then
    PNAME=$(ps -p $PID -o comm= 2>/dev/null)
    if [ "$PNAME" != "nginx" ]; then
        echo "杀死占用 80 端口的进程: $PID ($PNAME)"
        kill -9 $PID 2>/dev/null || true
    fi
fi

# 5. 清理 Docker 资源
echo "清理 Docker 资源..."
docker system prune -af --volumes

echo ""
echo "✅ 清理完成！"
echo ""
echo "🚀 开始重新部署..."
echo ""

# 6. 重新构建
echo "构建镜像..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 7. 启动服务
echo "启动服务..."
docker-compose -f docker-compose.prod.yml up -d

# 8. 等待
echo "等待服务启动..."
sleep 25

# 9. 检查状态
echo ""
echo "=========================================="
echo "服务状态:"
echo "=========================================="
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "=========================================="
echo "端口占用情况:"
echo "=========================================="
netstat -tlnp 2>/dev/null | grep -E ':(80|3002) ' || ss -tlnp 2>/dev/null | grep -E ':(80|3002) '

echo ""
echo "=========================================="
echo "✅ 部署完成！"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  - 前端: http://game.akinokuni.cn/"
echo "  - PostgREST: http://localhost:3002/"
echo ""
echo "查看日志:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo ""
