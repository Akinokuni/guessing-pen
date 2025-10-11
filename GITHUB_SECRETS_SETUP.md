# GitHub Secrets 配置指南

## 🔑 需要配置的Secrets

基于你已创建的ACR仓库，需要在GitHub中配置以下Secrets：

### 1. 进入GitHub Secrets设置
1. 打开GitHub仓库页面
2. 点击 **Settings** 标签
3. 在左侧菜单中选择 **Secrets and variables** → **Actions**
4. 点击 **New repository secret**

### 2. 添加ACR访问凭证

#### ACR_USERNAME
- **名称**: `ACR_USERNAME`
- **值**: 你的阿里云ACR用户名
- **格式**: `你的阿里云账号@实例ID`
- **示例**: `your-account@crpi-1dj58zvwo0jdkh2y`

#### ACR_PASSWORD
- **名称**: `ACR_PASSWORD`
- **值**: 你的ACR固定密码（不是阿里云登录密码）

### 3. 获取ACR访问凭证

1. **登录阿里云ACR控制台**
   - 访问: https://cr.console.aliyun.com/
   - 选择你的实例

2. **进入访问凭证页面**
   - 点击左侧菜单的"访问凭证"
   - 查看或设置固定密码

3. **记录凭证信息**
   - 用户名格式: `账号@实例ID`
   - 密码: 固定密码（推荐设置）

### 4. 验证配置

配置完成后，可以通过以下方式验证：

#### 方法1: 重新触发GitHub Actions
```bash
git commit --allow-empty -m "test: 验证ACR配置"
git push origin main
```

#### 方法2: 本地测试（可选）
```bash
export ACR_USERNAME="your-username@instance-id"
export ACR_PASSWORD="your-acr-password"
bash scripts/deployment/acr-repository-setup.sh
```

## 🎯 预期结果

配置正确后，GitHub Actions应该能够：
- ✅ 成功登录ACR
- ✅ 构建Docker镜像
- ✅ 推送镜像到ACR仓库
- ✅ 完成部署流程

## ❓ 常见问题

### Q: 在哪里找到实例ID？
A: 在ACR控制台首页可以看到实例ID，格式如 `crpi-xxxxxxxxx`

### Q: 用户名格式不确定？
A: 在"访问凭证"页面会显示完整的用户名格式

### Q: 密码应该用哪个？
A: 使用ACR的固定密码，不是阿里云账号密码

---

**下一步**: 配置完Secrets后，推送代码触发部署测试！