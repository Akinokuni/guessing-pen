# 快速部署指南

## 服务器信息

- **IP**: 47.115.146.78
- **SSH**: 已配置密钥认证
- **Docker**: 需要安装
- **端口**: 80, 3000

## 🚀 一键部署

### 步骤1: 在服务器上初始化环境

SSH登录服务器：

```bash
ssh root@47.115.146.78
```

下载并运行初始化脚本：

```bash
curl -sSL https://raw.githubusercontent.com/Akinokuni/guessing-pen/main/scripts/deployment/setup-server.sh -o setup-server.sh
chmod +x setup-server.sh
sudo ./setup-server.sh all
```

### 步骤2: 配置环境变量

编辑 `/opt/guessing-pen/.env`：

```bash
sudo nano /opt/guessing-pen/.env
```

填入以下内容：

```bash
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
```

保存并退出（Ctrl+X, Y, Enter）

### 步骤3: 首次部署

```bash
cd /opt/guessing-pen
sudo ./setup-server.sh deploy
```

### 步骤4: 验证部署

```bash
# 检查容器状态
docker ps

# 测试健康检查
curl http://localhost:3000/api/health

# 测试外部访问
curl http://47.115.146.78:3000/api/health
```

## ✅ GitHub Secrets 配置

你的GitHub Secrets已配置：

| Secret | 值 | 状态 |
|--------|-----|------|
| `PROD_SERVER_HOST` | 47.115.146.78 | ✅ |
| `PROD_SERVER_USER` | root | ✅ |
| `PROD_SERVER_SSH_KEY` | (私钥) | ✅ |
| `ACR_USERNAME` | (用户名) | ✅ |
| `ACR_PASSWORD` | (密码) | ✅ |

## 🔄 自动部署流程

配置完成后，每次推送代码：

```bash
git add .
git commit -m "feat: 新功能"
git push origin main
```

GitHub Actions会自动：
1. 构建Docker镜像
2. 推送到ACR
3. SSH连接服务器
4. 拉取最新镜像
5. 重启服务
6. 健康检查

## 📋 常用命令

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

### 更新镜像

```bash
cd /opt/guessing-pen
docker compose pull
docker compose up -d
```

### 清理资源

```bash
# 清理未使用的镜像
docker image prune -f

# 清理所有未使用的资源
docker system prune -a
```

## 🔧 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker logs guessing-pen-app

# 检查环境变量
docker exec guessing-pen-app env | grep DB_
```

### 无法访问应用

```bash
# 检查容器状态
docker ps

# 检查端口
netstat -tlnp | grep 3000

# 检查防火墙
sudo ufw status
```

### 数据库连接失败

```bash
# 测试数据库连接
docker exec guessing-pen-app curl http://localhost:3000/api/health
```

## 🌐 访问地址

部署成功后，访问：

- **应用**: http://47.115.146.78:3000
- **健康检查**: http://47.115.146.78:3000/api/health
- **排行榜**: http://47.115.146.78:3000/api/leaderboard

## 📞 需要帮助？

1. 查看GitHub Actions日志
2. 查看服务器应用日志
3. 检查环境变量配置
4. 联系项目维护团队

---

**服务器**: 47.115.146.78  
**更新日期**: 2025-10-11
