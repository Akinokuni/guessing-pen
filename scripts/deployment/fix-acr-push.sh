#!/bin/bash

#==============================================================================
# 脚本名称: fix-acr-push.sh
# 脚本描述: 修复ACR推送问题的快速脚本
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示问题诊断
diagnose_problem() {
    log_info "诊断ACR推送问题..."
    
    echo ""
    echo "🔍 当前错误分析："
    echo "错误信息: push access denied, repository does not exist or may require authorization"
    echo ""
    echo "可能的原因："
    echo "1. ❌ 阿里云ACR仓库不存在"
    echo "2. ❌ GitHub Secrets中的ACR凭证不正确"
    echo "3. ❌ ACR用户权限不足"
    echo "4. ❌ 仓库访问权限设置问题"
    echo ""
}

# 提供解决方案
provide_solutions() {
    log_info "提供解决方案..."
    
    cat << 'EOF'

🔧 解决方案步骤
================

方案1: 检查GitHub Secrets配置
-----------------------------
1. 进入GitHub仓库 → Settings → Secrets and variables → Actions
2. 检查以下Secrets是否存在且正确：
   - ACR_USERNAME: 阿里云ACR用户名
   - ACR_PASSWORD: 阿里云ACR密码（不是阿里云账号密码！）

方案2: 创建ACR仓库
------------------
1. 登录阿里云控制台: https://cr.console.aliyun.com/
2. 进入容器镜像服务 ACR
3. 选择个人实例（深圳地域）
4. 创建命名空间: guessing-pen
5. 创建仓库:
   - guessing-pen-frontend (公开)
   - guessing-pen-api (公开)

方案3: 获取正确的ACR凭证
-----------------------
1. 在ACR控制台 → 访问凭证
2. 设置固定密码（推荐）
3. 记录用户名格式: 你的阿里云账号@你的实例ID
4. 使用固定密码，不是阿里云登录密码

方案4: 本地测试ACR连接
---------------------
运行以下命令测试：

export ACR_USERNAME="your-acr-username"
export ACR_PASSWORD="your-acr-password"
bash scripts/deployment/acr-repository-setup.sh

方案5: 临时使用Docker Hub
------------------------
如果ACR问题无法快速解决，可以临时切换到Docker Hub：

1. 修改 .github/workflows/simple-deploy.yml
2. 将ACR_REGISTRY改为docker.io
3. 设置DOCKER_USERNAME和DOCKER_PASSWORD

EOF
}

# 生成测试命令
generate_test_commands() {
    log_info "生成测试命令..."
    
    cat << 'EOF'

🧪 测试命令
===========

# 1. 测试Docker登录
echo "$ACR_PASSWORD" | docker login crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com -u "$ACR_USERNAME" --password-stdin

# 2. 测试推送权限
docker pull hello-world:latest
docker tag hello-world:latest crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/test:latest
docker push crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/test:latest

# 3. 验证仓库设置
bash scripts/deployment/acr-repository-setup.sh

# 4. 重新触发GitHub Actions
git commit --allow-empty -m "trigger: 重新触发部署"
git push origin main

EOF
}

# 创建临时Docker Hub配置
create_dockerhub_fallback() {
    log_info "创建Docker Hub备用配置..."
    
    local fallback_file=".github/workflows/simple-deploy-dockerhub.yml"
    
    cat > "${fallback_file}" << 'EOF'
name: 简化部署流程 (Docker Hub)

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  # Docker Hub配置
  DOCKER_REGISTRY: docker.io
  DOCKER_NAMESPACE: your-dockerhub-username
  
  # 镜像名称
  FRONTEND_IMAGE: guessing-pen-frontend
  API_IMAGE: guessing-pen-api
  
  # Node.js版本
  NODE_VERSION: '18'

jobs:
  # 代码质量检查和测试
  test:
    name: 代码检查和测试
    runs-on: ubuntu-latest
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
      
      - name: 设置Node.js环境
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: 安装依赖
        run: npm ci
      
      - name: 代码格式检查
        run: npm run lint
        continue-on-error: false
      
      - name: TypeScript类型检查
        run: npm run type-check
        continue-on-error: false
      
      - name: 构建应用
        run: npm run build
        env:
          NODE_ENV: production

  # Docker镜像构建和推送
  build-and-push:
    name: 构建并推送镜像
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
      
      - name: 设置Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: 登录Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: 生成镜像标签
        id: meta
        run: |
          GIT_COMMIT=$(git rev-parse --short HEAD)
          BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
          
          FRONTEND_IMAGE_FULL="${{ env.DOCKER_NAMESPACE }}/${{ env.FRONTEND_IMAGE }}"
          
          echo "frontend-image=$FRONTEND_IMAGE_FULL" >> $GITHUB_OUTPUT
          echo "git-commit=$GIT_COMMIT" >> $GITHUB_OUTPUT
          echo "build-date=$BUILD_DATE" >> $GITHUB_OUTPUT
      
      - name: 构建并推送前端镜像
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            ${{ steps.meta.outputs.frontend-image }}:latest
            ${{ steps.meta.outputs.frontend-image }}:${{ steps.meta.outputs.git-commit }}
          build-args: |
            BUILD_DATE=${{ steps.meta.outputs.build-date }}
            GIT_COMMIT=${{ steps.meta.outputs.git-commit }}
            NODE_ENV=production
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: 输出镜像信息
        run: |
          echo "🎉 镜像构建完成！"
          echo "前端镜像: ${{ steps.meta.outputs.frontend-image }}:latest"
          echo "Git提交: ${{ steps.meta.outputs.git-commit }}"
EOF
    
    log_success "Docker Hub备用配置已创建: ${fallback_file}"
    echo ""
    echo "使用Docker Hub备用方案："
    echo "1. 在GitHub Secrets中设置 DOCKER_USERNAME 和 DOCKER_PASSWORD"
    echo "2. 修改配置中的 DOCKER_NAMESPACE 为你的Docker Hub用户名"
    echo "3. 重命名此文件为 simple-deploy.yml 替换现有配置"
}

# 主函数
main() {
    echo "🚨 ACR推送问题修复助手"
    echo "========================"
    echo ""
    
    diagnose_problem
    provide_solutions
    generate_test_commands
    
    echo ""
    read -p "是否创建Docker Hub备用配置？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_dockerhub_fallback
    fi
    
    echo ""
    log_info "修复建议已生成完成！"
    echo ""
    echo "📋 下一步行动："
    echo "1. 优先解决ACR配置问题（推荐）"
    echo "2. 或使用Docker Hub作为临时方案"
    echo "3. 运行测试命令验证配置"
    echo "4. 重新触发GitHub Actions部署"
}

# 显示帮助
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help          显示帮助信息
    --dockerhub-only    只创建Docker Hub配置
    --test-only         只显示测试命令

描述:
    修复ACR推送问题的快速脚本，提供多种解决方案

EOF
}

# 参数处理
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --dockerhub-only)
            create_dockerhub_fallback
            exit 0
            ;;
        --test-only)
            generate_test_commands
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 执行主函数
main "$@"