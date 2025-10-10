# 部署检查清单

## 📋 部署前检查

### 环境准备
- [ ] 已安装 Docker 和 Docker Compose
- [ ] 已配置 `.env` 文件（从 `.env.example` 复制）
- [ ] 已设置 Supabase 配置（如使用云服务）

### 文件完整性检查
- [ ] `Dockerfile` 存在
- [ ] `docker-compose.yml` 存在
- [ ] `nginx.conf` 存在
- [ ] `supabase/config.toml` 存在
- [ ] `supabase/migrations/001_initial_schema.sql` 存在
- [ ] `deploy.sh` 或 `deploy.bat` 存在且可执行

## 🚀 部署步骤

### 1. 数据库设置

#### 选项 A：Supabase 云服务
- [ ] 创建 Supabase 项目
- [ ] 获取项目 URL 和 API Key
- [ ] 在 `.env` 中配置 Supabase 变量
- [ ] 执行数据库迁移（CLI 或手动）
- [ ] 验证表和视图创建成功

#### 选项 B：本地 Docker 数据库
- [ ] 运行 `./deploy.sh dev` 启动本地数据库
- [ ] 验证数据库连接（端口 54322）
- [ ] 检查数据库初始化是否成功

### 2. 应用部署

#### Docker 部署
- [ ] 运行部署脚本：`./deploy.sh` 或 `deploy.bat`
- [ ] 等待构建完成（可能需要几分钟）
- [ ] 检查容器状态：`docker-compose ps`
- [ ] 验证健康检查：访问 `http://localhost/health`

#### 手动部署
- [ ] 构建镜像：`docker build -t guessing-pen-challenge .`
- [ ] 运行容器：`docker run -d -p 80:80 guessing-pen-challenge`
- [ ] 检查容器状态：`docker ps`

### 3. 功能验证

#### 基础功能
- [ ] 访问主页：`http://localhost`
- [ ] 页面正常加载，无 JavaScript 错误
- [ ] 卡片图片正常显示
- [ ] 游戏流程可以正常进行

#### 数据库功能
- [ ] 可以输入昵称开始游戏
- [ ] 可以提交答案
- [ ] 排行榜正常显示
- [ ] 统计数据正常显示

#### 性能检查
- [ ] 页面加载速度合理（< 3秒）
- [ ] 图片加载正常
- [ ] 移动端适配良好

## 🔧 故障排除

### 常见问题

#### 构建失败
- [ ] 检查 Docker 是否正常运行
- [ ] 检查网络连接（可能需要镜像加速）
- [ ] 查看构建日志：`docker-compose logs`

#### 服务无法启动
- [ ] 检查端口是否被占用（80, 443）
- [ ] 检查 `.env` 文件配置
- [ ] 查看容器日志：`docker-compose logs guessing-pen-frontend`

#### 数据库连接失败
- [ ] 验证 Supabase URL 和 API Key
- [ ] 检查网络连接
- [ ] 确认数据库迁移已执行
- [ ] 查看数据库日志：`docker-compose logs supabase-db`

#### 页面无法访问
- [ ] 检查防火墙设置
- [ ] 确认容器正在运行：`docker-compose ps`
- [ ] 检查 nginx 配置
- [ ] 查看 nginx 日志：`docker-compose logs guessing-pen-frontend`

### 日志查看命令

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs guessing-pen-frontend
docker-compose logs supabase-db

# 实时查看日志
docker-compose logs -f

# 查看最近的日志
docker-compose logs --tail=50
```

## 📊 监控和维护

### 定期检查
- [ ] 检查容器运行状态
- [ ] 监控磁盘空间使用
- [ ] 检查日志文件大小
- [ ] 验证数据库备份（如适用）

### 更新部署
- [ ] 拉取最新代码
- [ ] 重新构建镜像
- [ ] 滚动更新服务
- [ ] 验证更新后功能正常

### 备份策略
- [ ] 定期备份数据库
- [ ] 备份配置文件
- [ ] 备份用户数据（如适用）

## 🆘 获取帮助

如果遇到问题，可以：

1. 查看项目文档：`README.md`、`SUPABASE_SETUP.md`
2. 检查 GitHub Issues
3. 查看 Docker 和 Supabase 官方文档
4. 联系项目维护者

---

**提示**: 建议在生产环境部署前，先在测试环境完整走一遍这个检查清单。