# 服务器自动部署设置指南

## 📋 前置要求

### 1. 服务器要求
- **操作系统**: Linux (Ubuntu 20.04+ 推荐)
- **内存**: 至少 2GB
- **磁盘**: 至少 20GB
- **网络**: 能访问阿里云ACR

### 2. 必需软件
- Docker
- Docker Compose
- SSH服务

## 🚀 服务器初始化

### 步骤1: 安装Docker

```bash
# 更新系统
sudo apt-get update
sudo apt-get upgrade -y

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加当前用户到docker组
sudo usermod -aG docker $USER

# 验证安装
docker --version
```

### 步骤2: 安装Docker Compose

```bash
# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 添加执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

### 步骤3: 创建项目目录

```bash
# 创建项目目录
sudo mkdir -p /opt/guessing-pen
sudo chown $USER:$USER /opt/guessing-pen
cd /opt/guessing-pen

# 创建docker-compose配置
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  frontend:
    image: crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest
    container_name: guessing-pen-frontend
    ports:
      - "80:80"
    restart: unless-stopped
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  default:
    name: guessing-pen-network
EOF
```

### 步骤4: 配置防火墙

```bash
# 如果使用ufw
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS (如果需要)
sudo ufw enable

# 如果使用阿里云安全组
# 在阿里云控制台添加规则：
# - 端口 22 (SSH)
# - 端口 80 (HTTP)
# - 端口 443 (HTTPS，可选)
```

### 步骤5: 生成SSH密钥（用于GitHub Actions）

```bash
# 在服务器上生成SSH密钥
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions -N ""

# 添加公钥到authorized_keys
cat ~/.ssh/github_actions.pub >> ~/.ssh/authorized_keys

# 显示私钥（复制到GitHub Secrets）
cat ~/.ssh/github_actions
```

## 🔑 配置GitHub Secrets

在GitHub仓库中添加以下Secrets：

### 必需的Secrets

1. **SERVER_HOST**
   - 值: 服务器IP地址或域名
   - 示例: `123.456.789.0` 或 `example.com`

2. **SERVER_USER**
   - 值: SSH登录用户名
   - 示例: `ubuntu` 或 `root`

3. **SERVER_SSH_KEY**
   - 值: 上面生成的私钥内容
   - 完整复制 `~/.ssh/github_actions` 文件内容

4. **SERVER_PORT** (可选)
   - 值: SSH端口
   - 默认: `22`

5. **ACR_USERNAME** (已配置)
   - 阿里云ACR用户名

6. **ACR_PASSWORD** (已配置)
   - 阿里云ACR密码

### 配置步骤

1. 进入GitHub仓库
2. Settings → Secrets and variables → Actions
3. 点击 "New repository secret"
4. 添加上述每个Secret

## 🧪 测试部署

### 手动测试

在服务器上手动测试部署流程：

```bash
# 登录ACR
echo "YOUR_ACR_PASSWORD" | docker login crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com -u "YOUR_ACR_USERNAME" --password-stdin

# 拉取镜像
docker pull crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest

# 启动服务
cd /opt/guessing-pen
docker-compose -f docker-compose.prod.yml up -d

# 检查状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

### 验证服务

```bash
# 检查容器状态
docker ps

# 测试HTTP访问
curl http://localhost

# 测试健康检查
curl http://localhost/health
```

## 🔄 自动部署流程

配置完成后，每次推送代码到main分支，GitHub Actions会自动：

1. ✅ 构建Docker镜像
2. ✅ 推送到阿里云ACR
3. ✅ SSH连接到服务器
4. ✅ 拉取最新镜像
5. ✅ 重启服务
6. ✅ 执行健康检查

## 📊 监控和维护

### 查看日志

```bash
# 实时日志
docker-compose -f docker-compose.prod.yml logs -f

# 最近100行日志
docker-compose -f docker-compose.prod.yml logs --tail=100

# 特定服务日志
docker logs guessing-pen-frontend
```

### 重启服务

```bash
cd /opt/guessing-pen
docker-compose -f docker-compose.prod.yml restart
```

### 更新镜像

```bash
cd /opt/guessing-pen
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

### 清理旧镜像

```bash
# 清理未使用的镜像
docker image prune -f

# 清理所有未使用的资源
docker system prune -f
```

## 🔒 安全建议

1. **使用非root用户**
   ```bash
   # 创建部署用户
   sudo adduser deploy
   sudo usermod -aG docker deploy
   ```

2. **配置SSH密钥认证**
   - 禁用密码登录
   - 只允许密钥认证

3. **定期更新系统**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   ```

4. **配置HTTPS**
   - 使用Let's Encrypt免费证书
   - 配置Nginx反向代理

## 🆘 故障排查

### 部署失败

1. **检查GitHub Actions日志**
   - 查看具体错误信息

2. **检查服务器连接**
   ```bash
   ssh -i ~/.ssh/github_actions user@server-ip
   ```

3. **检查Docker服务**
   ```bash
   sudo systemctl status docker
   ```

4. **检查容器日志**
   ```bash
   docker-compose -f docker-compose.prod.yml logs
   ```

### 服务无法访问

1. **检查容器状态**
   ```bash
   docker ps
   ```

2. **检查端口占用**
   ```bash
   sudo netstat -tlnp | grep :80
   ```

3. **检查防火墙**
   ```bash
   sudo ufw status
   ```

## 📞 获取帮助

如果遇到问题：
1. 查看GitHub Actions运行日志
2. 查看服务器Docker日志
3. 检查网络连接和防火墙设置

---

**最后更新**: 2025-10-11  
**维护者**: Kiro AI Assistant
