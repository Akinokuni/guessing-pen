#!/bin/bash

# 猜猜笔挑战 - 一键部署脚本

set -e

echo "🚀 开始部署猜猜笔挑战..."

# 检查必要的工具
check_requirements() {
    echo "📋 检查部署环境..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    echo "✅ 环境检查通过"
}

# 设置环境变量
setup_environment() {
    echo "🔧 设置环境变量..."
    
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            echo "📝 已创建 .env 文件，请根据需要修改配置"
        else
            echo "⚠️  未找到 .env.example 文件"
        fi
    fi
    
    # 设置构建时间和版本
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    export VERSION=${VERSION:-$(date +%Y%m%d-%H%M%S)}
    
    echo "📅 构建时间: $BUILD_DATE"
    echo "🏷️  版本标签: $VERSION"
}

# 构建和启动服务
deploy_services() {
    echo "🏗️  构建 Docker 镜像..."
    docker-compose build --no-cache
    
    echo "🚀 启动服务..."
    docker-compose up -d
    
    echo "⏳ 等待服务启动..."
    sleep 10
    
    # 健康检查
    if curl -f http://localhost/health &> /dev/null; then
        echo "✅ 服务启动成功！"
        echo "🌐 访问地址: http://localhost"
    else
        echo "❌ 服务启动失败，请检查日志"
        docker-compose logs
        exit 1
    fi
}

# 显示部署信息
show_deployment_info() {
    echo ""
    echo "🎉 部署完成！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 应用访问地址: http://localhost"
    echo "🔍 健康检查: http://localhost/health"
    echo ""
    echo "📊 服务状态:"
    docker-compose ps
    echo ""
    echo "📝 常用命令:"
    echo "  查看日志: docker-compose logs -f"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart"
    echo "  更新服务: docker-compose pull && docker-compose up -d"
    echo ""
    echo "🗄️  数据库信息:"
    echo "  如需使用本地数据库，请运行: docker-compose --profile dev up -d"
    echo "  数据库端口: 54322"
    echo "  用户名: postgres"
    echo "  密码: 请查看 .env 文件中的 POSTGRES_PASSWORD"
}

# 初始化数据库
init_database() {
    echo "🗄️  检查数据库初始化..."
    
    if [ -f "database/init.sql" ]; then
        read -p "是否需要初始化数据库？(y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "📋 开始初始化数据库..."
            cd database
            if [ -f "deploy-db.sh" ]; then
                chmod +x deploy-db.sh
                ./deploy-db.sh
            else
                echo "⚠️  未找到数据库部署脚本"
            fi
            cd ..
        fi
    fi
}

# 主函数
main() {
    check_requirements
    setup_environment
    init_database
    deploy_services
    show_deployment_info
}

# 处理命令行参数
case "${1:-}" in
    "stop")
        echo "🛑 停止服务..."
        docker-compose down
        echo "✅ 服务已停止"
        ;;
    "restart")
        echo "🔄 重启服务..."
        docker-compose restart
        echo "✅ 服务已重启"
        ;;
    "logs")
        echo "📋 查看日志..."
        docker-compose logs -f
        ;;
    "clean")
        echo "🧹 清理资源..."
        docker-compose down -v --rmi all
        echo "✅ 清理完成"
        ;;
    "dev")
        echo "🔧 启动开发环境（包含本地数据库）..."
        docker-compose --profile dev up -d
        echo "✅ 开发环境已启动"
        ;;
    *)
        main
        ;;
esac