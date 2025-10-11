# 阿里云ACR Docker镜像仓库设置指南

## 概述

本文档详细说明如何设置阿里云容器镜像服务(ACR)，用于存储和管理项目的Docker镜像。

## 前置条件

1. 阿里云账号
2. 已开通容器镜像服务
3. Docker环境
4. 阿里云CLI工具（可选）

## ACR服务配置

### 1. 创建镜像仓库

#### 1.1 登录阿里云控制台
- 访问 [阿里云容器镜像服务控制台](https://cr.console.aliyun.com/)
- 选择合适的地域（建议：华东1-杭州）

#### 1.2 创建命名空间
```bash
命名空间名称: guessing-pen
可见性: 公开
自动创建仓库: 开启
默认仓库类型: 公开
```

#### 1.3 创建镜像仓库
创建以下两个仓库：

**前端仓库**:
```
仓库名称: guessing-pen-frontend
摘要: 旮旯画师前端应用镜像
详情: 基于React + TypeScript的前端应用Docker镜像
仓库类型: 公开
```

**API仓库**:
```
仓库名称: guessing-pen-api
摘要: 旮旯画师API服务镜像
详情: 基于Node.js + Express的API服务Docker镜像
仓库类型: 公开
```

#### 1.4 获取访问凭证
在ACR控制台中：
1. 点击右上角的用户头像
2. 选择"访问凭证"
3. 设置Registry登录密码
4. 记录用户名和密码（用于GitHub Secrets配置）

### 2. 配置信息

#### 2.1 ACR基本信息
```bash
注册表地址: registry.cn-hangzhou.aliyuncs.com
地域: 华东1 (杭州)
命名空间: guessing-pen
版本: 个人版
```

#### 2.2 镜像地址
```bash
前端镜像: registry.cn-hangzhou.aliyuncs.com/guessing-pen/guessing-pen-frontend
API镜像: registry.cn-hangzhou.aliyuncs.com/guessing-pen/guessing-pen-api
```

## GitHub Actions配置

### 1. GitHub Secrets设置

在GitHub仓库的Settings > Secrets and variables > Actions中添加以下Secrets：

```bash
ACR_REGISTRY=registry.cn-hangzhou.aliyuncs.com
ACR_NAMESPACE=guessing-pen
ACR_USERNAME=<你的阿里云ACR用户名>
ACR_PASSWORD=<你的阿里云ACR密码>
```

### 2. 工作流配置

CI/CD工作流已配置为自动使用这些Secrets：

```yaml
env:
  ACR_REGISTRY: registry.cn-hangzhou.aliyuncs.com
  ACR_NAMESPACE: guessing-pen

jobs:
  build:
    steps:
      - name: 登录阿里云ACR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.ACR_REGISTRY }}
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}
```

## 本地开发配置

### 1. Docker登录
```bash
# 使用环境变量登录
echo "$ACR_PASSWORD" | docker login registry.cn-hangzhou.aliyuncs.com -u "$ACR_USERNAME" --password-stdin

# 或者交互式登录
docker login registry.cn-hangzhou.aliyuncs.com
```

### 2. 构建和推送镜像
```bash
# 使用项目脚本
bash scripts/deployment/acr-push.sh

# 或者手动构建推送
docker build -t registry.cn-hangzhou.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest .
docker push registry.cn-hangzhou.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest
```

## 验证配置

### 1. 使用验证脚本
```bash
# 设置环境变量
export ACR_REGISTRY="registry.cn-hangzhou.aliyuncs.com"
export ACR_NAMESPACE="guessing-pen"
export ACR_USERNAME="your-username"
export ACR_PASSWORD="your-password"

# 运行验证脚本
bash scripts/deployment/acr-config-validator.sh
```

### 2. 手动验证
```bash
# 测试登录
docker login registry.cn-hangzhou.aliyuncs.com

# 拉取测试镜像
docker pull hello-world:latest

# 标记并推送到ACR
docker tag hello-world:latest registry.cn-hangzhou.aliyuncs.com/guessing-pen/test:latest
docker push registry.cn-hangzhou.aliyuncs.com/guessing-pen/test:latest

# 清理测试镜像
docker rmi registry.cn-hangzhou.aliyuncs.com/guessing-pen/test:latest
```

## 故障排查

### 常见问题

#### 1. 403 Forbidden错误
**原因**: 用户名或密码错误，或者权限不足
**解决方案**:
- 检查ACR用户名和密码是否正确
- 确认用户有推送权限
- 重新设置Registry登录密码

#### 2. 网络连接超时
**原因**: 网络连接问题或防火墙阻止
**解决方案**:
- 检查网络连接
- 确认防火墙设置
- 尝试使用VPN或代理

#### 3. 镜像推送失败
**原因**: 镜像过大或网络不稳定
**解决方案**:
- 优化Dockerfile减小镜像大小
- 使用多阶段构建
- 重试推送操作

### 调试命令
```bash
# 检查Docker状态
docker info

# 检查登录状态
docker system info | grep -i registry

# 查看镜像列表
docker images

# 查看推送日志
docker push <image> --verbose
```

## 安全最佳实践

### 1. 访问控制
- 使用RAM用户而非主账号
- 设置最小权限原则
- 定期轮换密码

### 2. 镜像安全
- 使用官方基础镜像
- 定期更新基础镜像
- 扫描镜像漏洞

### 3. 网络安全
- 使用HTTPS连接
- 配置访问白名单
- 启用访问日志

## 监控和维护

### 1. 镜像管理
- 定期清理旧镜像
- 监控存储使用量
- 设置镜像保留策略

### 2. 访问监控
- 查看推送拉取统计
- 监控异常访问
- 设置告警规则

---

**创建日期**: 2025年10月11日  
**维护者**: DevOps团队  
**下次审核**: 每月检查一次

## 相关文档
- [GitHub Secrets配置指南](.github/secrets/SECRETS_SETUP.md)
- [CI/CD工作流配置](.github/workflows/ci-cd.yml)
- [ACR配置验证脚本](scripts/deployment/acr-config-validator.sh)