# 立即部署到服务器 47.115.146.78

## 前提条件
- ✅ Docker已安装
- ✅ SSH密钥已配置
- ✅ 数据库信息已知

## 🚀 快速部署（3步）

### 1. 在服务器上创建配置文件

SSH登录服务器：
```bash
ssh root@47.115.146.78
```

创建项目目录和配置：
```bash
mkdir -p /opt/guessing-pen
cd /opt/guessing-pen

# 创建.env文件
cat > .env << 'EOF'
# PostgreSQL数据库
DB_HOST=pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com
DB_PORT=5432
DB_USER=aki
DB_PASSWORD=20138990398QGL@gmailcom
DB_NAME=postgres
DB_SSL=false

# ACR配置
ACR_REGISTRY=crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com
ACR_NAMESPACE=guessing-pen
ACR_USERNAME=你的ACR用户名
ACR_PASSWORD=你的ACR密码

# 镜像配置
IMAGE_TAG=latest
EOF

chmod 600 .env
```

### 2. 编辑ACR凭证

```bash
nano .env
```

修改这两行：
- `ACR_USERNAME=你的ACR用户名`
- `ACR_PASSWORD=你的ACR密码`

保存：`Ctrl+X`, `Y`, `Enter`

### 3. 运行部署脚本

```bash
# 下载部署脚本
curl -sSL https://raw.githubusercontent.com/Akinokuni/guessing-pen/main/scripts/deployment/server-deploy.sh -o deploy.sh
chmod +x deploy.sh

# 加载环境变量
source .env

# 执行部署
./deploy.sh
```

## ✅ 验证部署

```bash
# 查看容器状态
docker ps

# 测试健康检查
curl http://localhost:3000/api/health

# 查看日志
docker logs guessing-pen-app
```

## 🌐 访问应用

- **应用**: http://47.115.146.78:3000
- **健康检查**: http://47.115.146.78:3000/api/health

## 📋 常用命令

```bash
cd /opt/guessing-pen

# 查看日志
docker logs -f guessing-pen-app

# 重启服务
docker compose restart

# 更新服务
source .env
docker pull $ACR_REGISTRY/$ACR_NAMESPACE/guessing-pen-frontend:latest
docker compose up -d
```

## 🔄 自动部署

配置完成后，每次推送代码到GitHub会自动部署！

---

**服务器**: 47.115.146.78  
**数据库**: pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com:5432
