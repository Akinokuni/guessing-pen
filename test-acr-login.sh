#!/bin/bash

# 测试ACR登录
# 使用方法: bash test-acr-login.sh

echo "🔐 测试阿里云ACR登录"
echo "===================="
echo ""

# ACR配置
ACR_REGISTRY="crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com"

echo "📋 请输入你的ACR用户名："
echo "提示: 个人版实例通常是你的阿里云账号（邮箱或手机号）"
read -r ACR_USERNAME

echo ""
echo "🔑 请输入你的ACR固定密码："
read -s ACR_PASSWORD

echo ""
echo "🧪 测试登录..."
echo ""

# 测试登录
if echo "$ACR_PASSWORD" | docker login "$ACR_REGISTRY" -u "$ACR_USERNAME" --password-stdin; then
    echo ""
    echo "✅ 登录成功！"
    echo ""
    echo "📝 请在GitHub Secrets中设置："
    echo "ACR_USERNAME=$ACR_USERNAME"
    echo "ACR_PASSWORD=<你的密码>"
    echo ""
    echo "🧪 测试推送..."
    
    # 测试推送
    docker pull hello-world:latest
    docker tag hello-world:latest "$ACR_REGISTRY/guessing-pen/test:latest"
    
    if docker push "$ACR_REGISTRY/guessing-pen/test:latest"; then
        echo ""
        echo "✅ 推送成功！ACR配置完全正确。"
        
        # 清理
        docker rmi "$ACR_REGISTRY/guessing-pen/test:latest" 2>/dev/null
        docker rmi hello-world:latest 2>/dev/null
    else
        echo ""
        echo "❌ 推送失败。可能的原因："
        echo "1. 仓库 guessing-pen/test 不存在"
        echo "2. 用户没有推送权限"
    fi
else
    echo ""
    echo "❌ 登录失败！"
    echo ""
    echo "💡 请检查："
    echo "1. 用户名格式是否正确"
    echo "   - 个人版: 直接使用阿里云账号（邮箱/手机号）"
    echo "   - 企业版: 账号@实例ID"
    echo ""
    echo "2. 密码是否是ACR固定密码（不是阿里云登录密码）"
    echo ""
    echo "3. 在ACR控制台检查："
    echo "   https://cr.console.aliyun.com/"
    echo "   - 访问凭证 → 查看用户名格式"
    echo "   - 访问凭证 → 重置固定密码"
fi
