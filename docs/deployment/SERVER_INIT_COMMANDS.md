# 服务器初始化命令

## 服务器信息
- **IP**: 47.115.146.78
- **用户**: root
- **SSH**: 已配置密钥认证

## 🚀 完整初始化流程

### 1. SSH登录服务器

```bash
ssh root@47.115.146.78
```

### 2. 更新系统

```bash
apt-get update
apt-get upgrade -y
```

### 3. 安装Docker

```bash
# 安装依赖
apt-get install -y ca-certificates curl gnupg lsb-release

# 添加Docker GPG密钥
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加Docker仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动Docker
systemctl start docker
systemctl enable docker

# 验证安装
docker --version
docker compose version
```

### 4. 创建项目目录

```bash
mkdir -p /opt/guessing-pen
cd /opt/guessing-pen
mkdir -p logs
```

### 5. 创建docker-compose.yml

```bash
cat > /opt/guessing-pen/docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    image: crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest
    container_name: guessing-pen-app
    restart: unless-stopped
    ports:
      - "80:80"
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT:-3306}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
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
      - guessing-pen-network

networks:
  guessing-pen-network:
    driver: bridge
EOF
```

### 6. 创建环境变量文件

```bash
cat > /opt/guessing-pen/.env << 'EOF'
# 数据库配置
DB_HOST=rm-wz9p6u2i5yz4uh5ue.mysql.rds.aliyuncs.com
DB_PORT=3306
DB_NAME=guessing_pen
DB_USER=guessing_pen_user
DB_PASSWORD=你的数据库密码

# ACR配置
ACR_REGISTRY=crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com
ACR_NAMESPACE=guessing-pen
ACR_USERNAME=你的ACR用户名
ACR_PASSWORD=你的ACR密码
EOF

chmod 600 /opt/guessing-pen/.env
```

### 7. 编辑环境变量（重要！）

```bash
nano /opt/guessing-pen/.env
```

**必须修改以下内容：**
- `DB_PASSWORD`: 你的数据库密码
- `ACR_USERNAME`: 你的ACR用户名（格式：账号@实例ID）
- `ACR_PASSWORD`: 你的ACR固定密码

保存并退出：`Ctrl+X`, `Y`, `Enter`

### 8. 配置防火墙

```bash
# 安装UFW
apt-get install -y ufw

# 配置规则
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 3000/tcp  # 应用端口

# 启用防火墙
ufw --force enable

# 查看状态
ufw status
```

### 9. 登录ACR并拉取镜像

```bash
cd /opt/guessing-pen

# 加载环境变量
source .env

# 登录ACR
echo $ACR_PASSWORD | docker login $ACR_REGISTRY -u $ACR_USERNAME --password-stdin

# 拉取镜像
docker pull crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest
```

### 10. 启动服务

```bash
cd /opt/guessing-pen
docker compose up -d
```

### 11. 验证部署

```bash
# 等待服务启动
sleep 15

# 查看容器状态
docker ps

# 查看日志
docker logs guessing-pen-app

# 测试健康检查
curl http://localhost:3000/api/health

# 测试外部访问
curl http://47.115.146.78:3000/api/health
```

## ✅ 验证清单

完成后检查：

- [ ] Docker已安装并运行
- [ ] 项目目录已创建
- [ ] docker-compose.yml已创建
- [ ] .env文件已配置正确的密码
- [ ] 防火墙已配置
- [ ] ACR登录成功
- [ ] 镜像拉取成功
- [ ] 容器正在运行
- [ ] 健康检查通过
- [ ] 可以外部访问

## 🔧 常用管理命令

### 查看服务状态

```bash
cd /opt/guessing-pen
docker compose ps
```

### 查看日志

```bash
# 实时日志
docker logs -f guessing-pen-app

# 最近100行
docker logs --tail 100 guessing-pen-app
```

### 重启服务

```bash
cd /opt/guessing-pen
docker compose restart
```

### 停止服务

```bash
cd /opt/guessing-pen
docker compose down
```

### 更新服务

```bash
cd /opt/guessing-pen
source .env
echo $ACR_PASSWORD | docker login $ACR_REGISTRY -u $ACR_USERNAME --password-stdin
docker compose pull
docker compose up -d
```

### 清理资源

```bash
# 清理未使用的镜像
docker image prune -f

# 清理所有未使用的资源
docker system prune -a -f
```

## 🔍 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker logs guessing-pen-app

# 检查环境变量
docker exec guessing-pen-app env | grep DB_

# 检查配置文件
cat /opt/guessing-pen/.env
```

### 无法访问应用

```bash
# 检查容器状态
docker ps

# 检查端口
netstat -tlnp | grep 3000

# 检查防火墙
ufw status

# 测试本地访问
curl http://localhost:3000/api/health
```

### ACR登录失败

```bash
# 检查凭证
cat /opt/guessing-pen/.env | grep ACR_

# 手动登录测试
docker login crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com
```

### 数据库连接失败

```bash
# 检查数据库配置
cat /opt/guessing-pen/.env | grep DB_

# 测试数据库连接（需要安装mysql-client）
apt-get install -y mysql-client
mysql -h rm-wz9p6u2i5yz4uh5ue.mysql.rds.aliyuncs.com -u guessing_pen_user -p guessing_pen
```

## 📊 监控命令

### 系统资源

```bash
# CPU和内存
htop

# 磁盘使用
df -h

# Docker资源
docker stats
```

### 应用监控

```bash
# 容器状态
docker compose ps

# 实时日志
docker logs -f guessing-pen-app

# 健康检查
curl http://localhost:3000/api/health
```

## 🔄 自动部署

初始化完成后，每次推送代码到GitHub，会自动：

1. ✅ 构建Docker镜像
2. ✅ 推送到ACR
3. ✅ SSH连接服务器
4. ✅ 拉取最新镜像
5. ✅ 重启服务
6. ✅ 健康检查

无需手动操作！

## 📞 需要帮助？

如果遇到问题：

1. 检查本文档的故障排查部分
2. 查看容器日志
3. 检查GitHub Actions运行状态
4. 联系项目维护团队

---

**服务器**: 47.115.146.78  
**创建日期**: 2025-10-11  
**维护者**: Kiro AI Assistant
