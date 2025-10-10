# 📚 项目文档索引

欢迎查阅旮旯画师之猜猜笔项目文档！

## 🚀 快速开始

新手？从这里开始：

1. **[主README](../README.md)** - 项目概览和快速开始
2. **[数据库快速启动](./database/QUICK_START_DB.md)** - 5分钟配置数据库
3. **[项目结构说明](./PROJECT_STRUCTURE.md)** - 了解项目组织

## 📖 文档分类

### 数据库文档 🗄️

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [快速启动指南](./database/QUICK_START_DB.md) | 最简单的开始方式 | ⭐ 推荐新手 |
| [应用就绪文档](./database/APPLICATION_CONNECTION_READY.md) | 完整配置和部署指南 | 详细参考 |
| [数据库总览](./database/README_DATABASE.md) | 数据库测试完成报告 | 了解现状 |
| [初始化成功报告](./database/DATABASE_INIT_SUCCESS.md) | 初始化详细信息 | 验证初始化 |
| [连接测试报告](./database/DATABASE_CONNECTION_TEST_REPORT.md) | 测试结果和故障排查 | 解决问题 |
| [权限问题说明](./database/ALIYUN_RDS_PERMISSION_ISSUE.md) | 阿里云RDS权限问题 | 遇到权限错误 |
| [手动设置文档](./database/MANUAL_DATABASE_SETUP.md) | 手动设置步骤 | 自定义配置 |

**数据库脚本位置**: `../database/`

### 部署文档 🚀

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [部署指南](./deployment/DEPLOYMENT.md) | Vercel部署步骤 | ⭐ 部署到生产 |
| [部署就绪文档](./deployment/DEPLOYMENT_READY.md) | 部署前准备 | 部署检查 |
| [部署检查清单](./deployment/DEPLOYMENT_CHECKLIST.md) | 部署步骤清单 | 逐步部署 |
| [PostgREST部署](./deployment/POSTGREST_DEPLOYMENT.md) | PostgREST配置 | 使用PostgREST |
| [Supabase设置](./deployment/SUPABASE_SETUP.md) | Supabase配置 | 使用Supabase |

### 迁移文档 🔄

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [迁移检查报告](./migration/MIGRATION_CHECK_REPORT.md) | 迁移状态检查 | 了解迁移状态 |
| [迁移总结](./migration/MIGRATION_SUMMARY.md) | 迁移详细信息 | 迁移参考 |

### 其他文档 📝

| 文档 | 说明 |
|------|------|
| [项目结构说明](./PROJECT_STRUCTURE.md) | 完整的项目结构文档 |
| [更新日志](../CHANGELOG.md) | 版本更新历史 |
| [许可证](../LICENSE) | MIT许可证 |

## 🎯 按场景查找

### 我想开始开发
1. 阅读 [主README](../README.md)
2. 配置数据库：[快速启动指南](./database/QUICK_START_DB.md)
3. 运行 `npm install && npm run dev`

### 我遇到数据库问题
1. 运行 `npm run db:check` 检查状态
2. 查看 [连接测试报告](./database/DATABASE_CONNECTION_TEST_REPORT.md)
3. 参考 [权限问题说明](./database/ALIYUN_RDS_PERMISSION_ISSUE.md)

### 我想部署到生产环境
1. 查看 [部署检查清单](./deployment/DEPLOYMENT_CHECKLIST.md)
2. 阅读 [部署指南](./deployment/DEPLOYMENT.md)
3. 配置环境变量
4. 运行 `npm run deploy`

### 我想了解项目结构
1. 阅读 [项目结构说明](./PROJECT_STRUCTURE.md)
2. 查看 `../src/` 目录
3. 参考代码注释

### 我想贡献代码
1. Fork项目
2. 阅读 [项目结构说明](./PROJECT_STRUCTURE.md)
3. 创建功能分支
4. 提交Pull Request

## 🔍 快速参考

### 常用命令

```bash
# 开发
npm run dev              # 启动前端
npm run dev:api          # 启动API服务器

# 数据库
npm run db:init          # 初始化数据库
npm run db:verify        # 验证数据
npm run db:check         # 检查状态
npm run db:test          # 测试连接

# 构建部署
npm run build            # 构建生产版本
npm run deploy           # 部署到Vercel
```

### 重要配置文件

```
.env                     # 环境变量
package.json             # NPM配置
vite.config.ts           # Vite配置
vercel.json              # Vercel配置
tailwind.config.js       # Tailwind配置
```

### 数据库信息

```
主机: pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com
端口: 5432
数据库: aki
Schema: public
```

### API端点

```
开发环境: http://localhost:3001/api/db
生产环境: https://your-app.vercel.app/api/db
```

## 📊 文档状态

| 类别 | 文档数 | 状态 |
|------|--------|------|
| 数据库 | 7 | ✅ 完整 |
| 部署 | 5 | ✅ 完整 |
| 迁移 | 2 | ✅ 完整 |
| 其他 | 3 | ✅ 完整 |
| **总计** | **17** | **✅ 完整** |

## 🆘 获取帮助

### 遇到问题？

1. **查看文档** - 先查找相关文档
2. **运行诊断** - 使用 `npm run db:check`
3. **查看日志** - 检查控制台输出
4. **搜索问题** - 在文档中搜索关键词

### 常见问题

**Q: 数据库连接超时？**  
A: 查看 [连接测试报告](./database/DATABASE_CONNECTION_TEST_REPORT.md) 的故障排查部分

**Q: 权限错误？**  
A: 查看 [权限问题说明](./database/ALIYUN_RDS_PERMISSION_ISSUE.md)

**Q: 如何部署？**  
A: 查看 [部署指南](./deployment/DEPLOYMENT.md)

**Q: 项目结构？**  
A: 查看 [项目结构说明](./PROJECT_STRUCTURE.md)

## 📝 文档贡献

发现文档问题或想要改进？

1. 在相应的Markdown文件中编辑
2. 确保格式正确
3. 提交Pull Request

## 🔗 外部资源

- [React文档](https://react.dev/)
- [Vite文档](https://vitejs.dev/)
- [Tailwind CSS文档](https://tailwindcss.com/)
- [PostgreSQL文档](https://www.postgresql.org/docs/)
- [Vercel文档](https://vercel.com/docs)
- [阿里云RDS文档](https://help.aliyun.com/product/26090.html)

## 📅 文档更新

- **最后更新**: 2025-10-10
- **版本**: 1.0.0
- **维护者**: 项目团队

---

**提示**: 使用 Ctrl+F (Windows) 或 Cmd+F (Mac) 在页面中搜索关键词
