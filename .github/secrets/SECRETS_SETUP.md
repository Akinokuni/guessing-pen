# GitHub Secrets 配置指南

## 概述

本文档说明如何配置GitHub Secrets以支持自动化部署流程。所有敏感信息都应通过GitHub Secrets进行安全存储和管理。

## 必需的Secrets配置

### 阿里云ACR相关
```
ACR_REGISTRY=crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com
ACR_NAMESPACE=guessing-pen
ACR_USERNAME=qgl233
ACR_PASSWORD=your-acr-password
```

**重要说明**:
- `ACR_REGISTRY`: 你的个人ACR实例地址
- `ACR_NAMESPACE`: 你的ACR命名空间，通常是项目名称
- `ACR_USERNAME`: 阿里云ACR用户名 (qgl233)
- `ACR_PASSWORD`: 阿里云ACR密码（建议使用访问凭证而非主账号密码）

### 服务器SSH连接
```
SERVER_HOST=your-server-ip
SERVER_USER=your-server-username
SERVER_SSH_KEY=your-private-ssh-key
SERVER_PORT=22
```

### 数据库配置
```
DB_HOST=your-database-host
DB_PORT=5432
DB_USER=your-database-user
DB_PASSWORD=your-database-password
DB_NAME=your-database-name
```

### 应用配置
```
NODE_ENV=production
API_PORT=3005
FRONTEND_PORT=80
```

### 通知配置（可选）
```
SLACK_WEBHOOK_URL=your-slack-webhook-url
EMAIL_NOTIFICATION=your-notification-email
```

## 配置步骤

### 1. 访问GitHub Secrets设置
1. 进入GitHub仓库
2. 点击 `Settings` 标签
3. 在左侧菜单中选择 `Secrets and variables` > `Actions`
4. 点击 `New repository secret`

### 2. 添加每个Secret
对于上述每个配置项：
1. 在 `Name` 字段输入Secret名称（如 `ACR_USERNAME`）
2. 在 `Secret` 字段输入对应的值
3. 点击 `Add secret` 保存

### 3. 验证配置
配置完成后，可以在Actions工作流中通过以下方式使用：
```yaml
env:
  ACR_USERNAME: ${{ secrets.ACR_USERNAME }}
  ACR_PASSWORD: ${{ secrets.ACR_PASSWORD }}
```

## 安全注意事项

### 权限管理
- 只有仓库管理员可以查看和修改Secrets
- Secrets在日志中会被自动遮掩
- 不要在代码中硬编码敏感信息

### 最佳实践
1. **最小权限原则**: 只配置必需的权限
2. **定期轮换**: 定期更新密码和密钥
3. **环境隔离**: 不同环境使用不同的凭证
4. **审计日志**: 定期检查Secrets使用情况

## 环境特定配置

### 开发环境
- 使用测试数据库
- 使用开发环境的ACR命名空间
- 可以使用较低的安全要求

### 生产环境
- 使用生产数据库
- 使用生产环境的ACR命名空间
- 启用所有安全检查
- 使用强密码和密钥

## 故障排查

### 常见问题
1. **Secret未生效**: 检查名称是否正确，注意大小写
2. **权限不足**: 确保使用的凭证有足够权限
3. **网络问题**: 检查服务器网络连接
4. **格式错误**: 确保SSH密钥格式正确

### 调试方法
```yaml
# 在工作流中添加调试步骤（注意不要输出敏感信息）
- name: Debug Environment
  run: |
    echo "ACR Registry: ${{ secrets.ACR_REGISTRY }}"
    echo "Server Host: ${{ secrets.SERVER_HOST }}"
    # 不要输出密码等敏感信息
```

---

**创建日期**: 2025年10月11日  
**维护者**: DevOps团队  
**下次审核**: 每月检查一次