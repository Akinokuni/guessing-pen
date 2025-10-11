# ACR推送问题修复指南

## 问题描述

Docker构建成功，但推送到阿里云ACR时失败：
```
ERROR: push access denied, repository does not exist or may require authorization
```

## 🔧 快速解决方案

### 方案1: 修复ACR配置（推荐）

#### 1. 检查阿里云ACR设置

1. **登录阿里云控制台**
   - 访问：https://cr.console.aliyun.com/
   - 选择地域：华南1（深圳）

2. **创建命名空间**
   - 命名空间名称：`guessing-pen`
   - 自动创建仓库：开启
   - 默认仓库类型：公开

3. **创建镜像仓库**（如果自动创建未生效）
   - 仓库名称：`guessing-pen-frontend`
   - 仓库类型：公开
   - 仓库名称：`guessing-pen-api`
   - 仓库类型：公开

#### 2. 获取正确的访问凭证

1. **设置固定密码**
   - 进入"访问凭证"页面
   - 点击"设置固定密码"
   - 记录用户名和密码

2. **用户名格式**
   ```
   格式：你的阿里云账号@实例ID
   示例：your-account@crpi-1dj58zvwo0jdkh2y
   ```

#### 3. 配置GitHub Secrets

在GitHub仓库设置中添加：
- `ACR_USERNAME`: 阿里云ACR用户名（格式如上）
- `ACR_PASSWORD`: ACR固定密码（不是阿里云登录密码）

#### 4. 验证配置

```bash
# 本地测试（可选）
export ACR_USERNAME="your-acr-username"
export ACR_PASSWORD="your-acr-password"
bash scripts/deployment/acr-repository-setup.sh
```

### 方案2: 使用Docker Hub（临时方案）

如果ACR问题无法快速解决，可以临时使用Docker Hub：

#### 1. 设置Docker Hub Secrets

在GitHub Secrets中添加：
- `DOCKER_USERNAME`: Docker Hub用户名
- `DOCKER_PASSWORD`: Docker Hub密码或访问令牌

#### 2. 使用备用配置

```bash
# 使用生成的Docker Hub配置
mv .github/workflows/simple-deploy-dockerhub.yml .github/workflows/simple-deploy.yml

# 修改配置中的用户名
# 编辑 .github/workflows/simple-deploy.yml
# 将 DOCKER_NAMESPACE 改为你的Docker Hub用户名
```

## 🧪 测试命令

### 测试ACR连接

```bash
# 1. 测试登录
echo "$ACR_PASSWORD" | docker login crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com -u "$ACR_USERNAME" --password-stdin

# 2. 测试推送
docker pull hello-world:latest
docker tag hello-world:latest crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/test:latest
docker push crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/test:latest
```

### 重新触发部署

```bash
git commit --allow-empty -m "trigger: 重新触发部署"
git push origin main
```

## 📋 常见问题

### Q: 用户名格式不确定？
A: 在ACR控制台的"访问凭证"页面可以看到完整的用户名格式

### Q: 密码是什么？
A: 使用ACR的固定密码，不是阿里云账号的登录密码

### Q: 仓库不存在？
A: 确保在ACR控制台中创建了对应的命名空间和仓库

### Q: 权限不足？
A: 检查ACR用户是否有推送权限，仓库类型是否设置正确

## 🔍 诊断工具

使用项目提供的诊断脚本：

```bash
# 完整诊断
bash scripts/deployment/fix-acr-push.sh

# 仓库设置验证
bash scripts/deployment/acr-repository-setup.sh

# ACR配置验证
bash scripts/deployment/acr-config-validator.sh
```

## ✅ 验证成功标志

当配置正确时，你会看到：
- GitHub Actions中Docker登录成功
- 镜像推送成功
- 在ACR控制台中可以看到推送的镜像

---

**最后更新**: 2025年10月11日  
**维护者**: Kiro AI Assistant