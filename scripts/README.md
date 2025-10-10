# 脚本目录说明

本目录包含项目的各种自动化脚本，按功能分类组织。

## 📁 目录结构

```
scripts/
├── deployment/          # 部署相关脚本
├── testing/            # 测试和诊断脚本
├── development/        # 开发辅助脚本
└── README.md          # 本说明文件
```

## 🚀 部署脚本 (deployment/)

### 主要部署脚本
- `deploy.sh` / `deploy.bat` - 主要部署脚本
- `deploy-final.sh` - 最终部署脚本
- `deploy-postgrest.sh` - PostgREST专用部署

### Docker部署
- `docker-deploy.sh` / `docker-deploy.bat` - Docker部署脚本

### 清理和重建
- `clean-and-deploy.sh` - 清理后部署
- `force-clean-deploy.sh` - 强制清理部署
- `rebuild-and-deploy.sh` - 重建后部署
- `redeploy-with-fix.sh` - 修复后重新部署

### 问题修复
- `fix-502.sh` - 修复502错误的脚本

## 🧪 测试脚本 (testing/)

### 数据库测试
- `test-db-connection.sh` - 测试数据库连接
- `test-db-api.html` - 数据库API测试页面

### PostgREST测试
- `test-postgrest.bat` - PostgREST测试 (Windows)
- `test-postgrest-only.sh` - 仅测试PostgREST

### 诊断工具
- `diagnose-postgrest.sh` - PostgREST诊断脚本

## 💻 开发脚本 (development/)

### 开发服务器
- `server-dev.js` - 开发环境API服务器

## 📋 使用说明

### 开发环境
```bash
# 启动开发服务器
node scripts/development/server-dev.js

# 测试数据库连接
bash scripts/testing/test-db-connection.sh
```

### 部署环境
```bash
# 标准部署
bash scripts/deployment/deploy.sh

# Docker部署
bash scripts/deployment/docker-deploy.sh

# 清理后部署
bash scripts/deployment/clean-and-deploy.sh
```

### 故障排查
```bash
# 诊断PostgREST
bash scripts/testing/diagnose-postgrest.sh

# 修复502错误
bash scripts/deployment/fix-502.sh
```

## ⚠️ 注意事项

1. **权限要求**: 部分脚本需要执行权限，使用前请确保：
   ```bash
   chmod +x scripts/deployment/*.sh
   chmod +x scripts/testing/*.sh
   ```

2. **环境变量**: 确保相关环境变量已正确配置
3. **依赖检查**: 运行前检查所需的工具是否已安装
4. **备份数据**: 部署前建议备份重要数据

## 🔧 维护

- 新增脚本请放入对应的分类目录
- 更新脚本后请同步更新本文档
- 定期检查脚本的有效性和安全性