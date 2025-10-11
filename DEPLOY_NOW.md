# 立即部署到服务器 47.115.146.78

## 前提条件
- ✅ Docker已安装
- ✅ SSH密钥已配置
- ✅ 数据库信息已配置（阿里云RDS PostgreSQL）

## 🚀 快速部署（2步）

### 1. 在服务器上创建配置文件

SSH登录服务器：
```bash
ssh root@47.115.146.78
```

创建项目目录和配置（直接使用.env.production）：
```bash
mkdir -p /opt/guessing-pen
cd /opt/guessing-pen

# 下载生产环境配置
curl -sSL https://raw.githubusercontent.com/Akinokuni/guessing-pen/main/.env.production -o .env

# 编辑ACR凭证
nano .env
```

**只需修改这两行：**
- `ACR_USERNAME=你的ACR用户名`
- `ACR_PASSWORD=你的ACR密码`

保存：`Ctrl+X`, `Y`, `Enter`

### 2. 运行部署脚本

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

## 📋 常用管理命令

```bash
cd /opt/guessing-pen

# 查看日志
docker logs -f guessing-pen-app

# 重启服务
docker compose restart

# 停止服务
docker compose down

# 更新服务（手动）
source .env
docker pull $ACR_REGISTRY/$ACR_NAMESPACE/guessing-pen-frontend:latest
docker compose up -d

# 查看容器状态
docker compose ps

# 清理旧镜像
docker image prune -f
```

## 🔄 自动部署

配置完成后，每次推送代码到GitHub main分支会自动：
1. 构建Docker镜像
2. 推送到阿里云ACR
3. SSH连接服务器
4. 拉取最新镜像
5. 重启服务
6. 执行健康检查

无需手动操作！

## 📊 配置说明

生产环境配置（.env.production）包含：
- ✅ PostgreSQL数据库配置（已填写）
- ✅ 服务器配置（已填写）
- ✅ API端点配置（已填写）
- ✅ Docker配置（已填写）
- ⚠️ ACR凭证（需要手动填写）

## 🔍 故障排查

如果部署失败：

1. **检查ACR凭证**
   ```bash
   cat .env | grep ACR_
   ```

2. **测试ACR登录**
   ```bash
   source .env
   echo $ACR_PASSWORD | docker login $ACR_REGISTRY -u $ACR_USERNAME --password-stdin
   ```

3. **查看详细日志**
   ```bash
   docker logs guessing-pen-app
   tail -f logs/production.log
   ```

4. **检查数据库连接**
   ```bash
   docker exec guessing-pen-app curl http://localhost:3000/api/health
   ```

---

**服务器**: 47.115.146.78  
**数据库**: pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com:5432  
**数据库名**: aki  
**配置文件**: .env.production
