# 服务器部署完整指南

## 服务器信息

- **IP地址**: 47.115.146.78
- **操作系统**: Ubuntu/Debian (推荐)
- **部署方式**: Docker + Docker Compose
- **自动部署**: GitHub Actions

## 🚀 快速开始

### 步骤1: 生成SSH密钥

在本地Windows机器上运行：

```powershell
cd C:\Documents\dev\guessing-pen
.\scripts\deployment\generate-ssh-key.ps1
```

这将生成：
- `guessing-pen-deploy-key` (私钥)
- `guessing-pen-deploy-key.pub` (公钥)

### 步骤2: 配置服务器SSH访问

登录服务器：

```bash
ssh root@47.115.146.78
```

添加公钥到服务器：

```bash
# 创建.ssh目录
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 添加公钥（替换为你的公钥内容）
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... github-actions@guessing-pen" >> ~/.ssh/authorized_keys

# 设置权限
chmod 600 ~/.ssh/authorized_keys
```

测试SSH连接：

```powershell
# 在本地测试
ssh -i guessing-pen-deploy-key root@47.115.146.78
```

### 步骤3: 初始化服务器环境

在服务器上运行：

```bash
# 下载并运行安装脚本
curl -sSL https://raw.githubusercontent.com/Akinokuni/guessing-pen/main/scripts/deployment/setup-server.sh -o setup-server.sh
chmod +x setup-server.sh

# 完整安装
sudo ./setup-server.sh all
```

或者手动执行各步骤：

```bash
# 1. 安装Docker
sudo ./setup-server.sh install

# 2. 配置项目
sudo ./setup-server.sh setup

# 3. 编辑环境变量
sudo nano /opt/guessing-pen/.env
```

### 步骤4: 配置环境变量

编辑 `/opt/guessing-pen/.env`：

```bash
# 数据库配置
DB_HOST=rm-wz9p6u2i5yz4uh5ue.mysql.rds.aliyuncs.com
DB_PORT=3306
DB_NAME=guessing_pen
DB_USER=guessing_pen_user
DB_PASSWORD=你的数据库密码

# ACR配置
ACR_REGISTRY=crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com
ACR_NAMESPACE=akinokuni
ACR_USERNAME=你的ACR用户名
ACR_PASSWORD=你的ACR密码
```

### 步骤5: 配置GitHub Secrets

在GitHub仓库设置中添加以下Secrets：

1. 进入: `Settings` → `Secrets and variables` → `Actions`
2. 点击 `New repository secret`
3. 添加以下Secrets：

| Secret名称 | 值 | 说明 |
|-----------|-----|------|
| `SERVER_HOST` | `47.115.146.78` | 服务器IP地址 |
| `SERVER_USER` | `root` | SSH用户名 |
| `SERVER_SSH_KEY` | 私钥内容 | 从guessing-pen-deploy-key复制 |
| `ACR_USERNAME` | 你的ACR用户名 | 阿里云ACR用户名 |
| `ACR_PASSWORD` | 你的ACR密码 | 阿里云ACR密码 |

### 步骤6: 首次手动部署

在服务器上：

```bash
# 登录ACR
cd /opt/guessing-pen
source .env
echo $ACR_PASSWORD | docker login --username $ACR_USERNAME --password-stdin $ACR_REGISTRY

# 部署应用
sudo ./setup-server.sh deploy
```

### 步骤7: 验证部署

检查服务状态：

```bash
# 查看容器状态
docker ps

# 查看日志
docker logs guessing-pen-app

# 测试健康检查
curl http://localhost:3000/api/health

# 测试外部访问
curl http://47.115.146.78:3000/api/health
```

## 🔄 自动部署流程

配置完成后，每次推送代码到main分支：

1. ✅ GitHub Actions自动触发
2. ✅ 构建Docker镜像
3. ✅ 推送到阿里云ACR
4. ✅ SSH连接服务器
5. ✅ 拉取最新镜像
6. ✅ 重启服务
7. ✅ 健康检查

## 📋 服务器管理命令

### Docker管理

```bash
# 查看运行中的容器
docker ps

# 查看所有容器
docker ps -a

# 查看日志
docker logs guessing-pen-app
docker logs -f guessing-pen-app  # 实时日志

# 重启容器
docker restart guessing-pen-app

# 停止容器
docker stop guessing-pen-app

# 启动容器
docker start guessing-pen-app
```

### Docker Compose管理

```bash
cd /opt/guessing-pen

# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看日志
docker compose logs
docker compose logs -f  # 实时日志

# 拉取最新镜像
docker compose pull

# 重新部署
docker compose up -d --force-recreate
```

### 系统管理

```bash
# 查看磁盘使用
df -h

# 查看内存使用
free -h

# 查看Docker磁盘使用
docker system df

# 清理未使用的Docker资源
docker system prune -a

# 查看端口占用
netstat -tlnp | grep 3000
```

## 🔧 故障排查

### 问题1: 容器无法启动

```bash
# 查看详细日志
docker logs guessing-pen-app

# 检查环境变量
docker exec guessing-pen-app env

# 检查配置文件
cat /opt/guessing-pen/.env
```

### 问题2: 无法访问应用

```bash
# 检查容器是否运行
docker ps | grep guessing-pen

# 检查端口映射
docker port guessing-pen-app

# 检查防火墙
sudo ufw status

# 测试本地访问
curl http://localhost:3000/api/health

# 检查阿里云安全组
# 确保开放了3000端口
```

### 问题3: 数据库连接失败

```bash
# 测试数据库连接
docker exec guessing-pen-app node -e "
const { Pool } = require('pg');
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD
});
pool.query('SELECT NOW()', (err, res) => {
  console.log(err ? err : res.rows);
  pool.end();
});
"

# 检查RDS白名单
# 确保服务器IP 47.115.146.78 在白名单中
```

### 问题4: ACR拉取镜像失败

```bash
# 重新登录ACR
cd /opt/guessing-pen
source .env
echo $ACR_PASSWORD | docker login --username $ACR_USERNAME --password-stdin $ACR_REGISTRY

# 手动拉取镜像
docker pull crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/akinokuni/guessing-pen:latest
```

## 🔐 安全配置

### SSH安全

```bash
# 禁用密码登录（仅使用密钥）
sudo nano /etc/ssh/sshd_config

# 修改以下配置
PasswordAuthentication no
PubkeyAuthentication yes

# 重启SSH服务
sudo systemctl restart sshd
```

### 防火墙配置

```bash
# 安装UFW
sudo apt-get install ufw

# 配置规则
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # 应用端口

# 启用防火墙
sudo ufw enable

# 查看状态
sudo ufw status
```

### 阿里云安全组

在阿里云控制台配置安全组规则：

| 协议 | 端口 | 源地址 | 说明 |
|------|------|--------|------|
| TCP | 22 | 你的IP/0.0.0.0/0 | SSH访问 |
| TCP | 80 | 0.0.0.0/0 | HTTP |
| TCP | 443 | 0.0.0.0/0 | HTTPS |
| TCP | 3000 | 0.0.0.0/0 | 应用端口 |

## 📊 监控和日志

### 应用日志

```bash
# 实时查看日志
docker logs -f guessing-pen-app

# 查看最近100行
docker logs --tail 100 guessing-pen-app

# 查看特定时间的日志
docker logs --since 1h guessing-pen-app
```

### 系统监控

```bash
# 安装监控工具
sudo apt-get install htop

# 查看系统资源
htop

# 查看Docker资源使用
docker stats
```

### 日志轮转

日志配置已在docker-compose.yml中设置：
- 最大文件大小: 10MB
- 保留文件数: 3个

## 🔄 更新和维护

### 手动更新

```bash
cd /opt/guessing-pen

# 拉取最新镜像
docker compose pull

# 重启服务
docker compose up -d --force-recreate
```

### 自动更新

推送代码到GitHub后自动触发部署。

### 备份

```bash
# 备份环境变量
cp /opt/guessing-pen/.env /opt/guessing-pen/.env.backup

# 备份日志
tar -czf logs-backup-$(date +%Y%m%d).tar.gz /opt/guessing-pen/logs/
```

## 📞 支持

遇到问题？

1. 查看本文档的故障排查部分
2. 检查GitHub Actions运行日志
3. 查看服务器应用日志
4. 联系项目维护团队

---

**创建日期**: 2025-10-11  
**服务器IP**: 47.115.146.78  
**维护者**: Kiro AI Assistant
