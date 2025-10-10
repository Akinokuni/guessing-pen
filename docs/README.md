# 项目文档目录

本目录包含项目的所有文档，按功能和阶段分类组织。

## 📁 目录结构

```
docs/
├── database/           # 数据库相关文档
├── deployment/         # 部署相关文档
├── migration/          # 迁移相关文档
├── project-status/     # 项目状态文档
├── PROJECT_CLEANUP_SUMMARY.md
├── PROJECT_STRUCTURE.md
└── README.md          # 本说明文件
```

## 🗄️ 数据库文档 (database/)

### 快速开始
- `QUICK_START_DB.md` - 数据库快速启动指南 ⭐
- `APPLICATION_CONNECTION_READY.md` - 应用连接就绪文档

### 设置和配置
- `MANUAL_DATABASE_SETUP.md` - 手动数据库设置
- `DATABASE_INIT_SUCCESS.md` - 数据库初始化成功报告

### 测试和验证
- `DATABASE_CONNECTION_TEST_REPORT.md` - 连接测试报告

### 问题解决
- `ALIYUN_RDS_PERMISSION_ISSUE.md` - 阿里云RDS权限问题
- `README_DATABASE.md` - 数据库说明文档

## 🚀 部署文档 (deployment/)

### 部署指南
- `DEPLOYMENT.md` - 主要部署文档 ⭐
- `DEPLOYMENT_READY.md` - 部署就绪文档
- `DEPLOYMENT_CHECKLIST.md` - 部署检查清单
- `DEPLOYMENT_CHECKLIST_FINAL.md` - 最终部署检查清单

### Docker部署
- `DOCKER_DEPLOYMENT.md` - Docker部署文档
- `DOCKER_DEPLOYMENT_SUMMARY.md` - Docker部署总结
- `DOCKER_QUICK_START.md` - Docker快速开始

### PostgREST部署
- `POSTGREST_DEPLOYMENT.md` - PostgREST部署文档
- `DEPLOY_WITH_POSTGREST.md` - 使用PostgREST部署

### 问题解决
- `ERROR_REPORT_502.md` - 502错误报告
- `TROUBLESHOOTING_502.md` - 502错误故障排查
- `FIX_502_SUMMARY.md` - 502错误修复总结

### 测试和验证
- `TEST_AND_DEPLOY.md` - 测试和部署文档

### 历史文档
- `SUPABASE_SETUP.md` - Supabase设置 (已废弃)

## 🔄 迁移文档 (migration/)

- `MIGRATION_SUMMARY.md` - 迁移总结
- `MIGRATION_CHECK_REPORT.md` - 迁移检查报告

## 📊 项目状态文档 (project-status/)

- `PROJECT_CLEANUP_COMPLETE.md` - 项目清理完成报告
- `PROJECT_STATUS.md` - 项目状态文档
- `REMOVE_SUPABASE_SUMMARY.md` - 移除Supabase总结

## 📋 项目概览文档

- `PROJECT_CLEANUP_SUMMARY.md` - 项目清理总结
- `PROJECT_STRUCTURE.md` - 项目结构文档

## 🎯 推荐阅读顺序

### 新开发者入门
1. `../README.md` - 项目主要说明
2. `database/QUICK_START_DB.md` - 数据库快速开始
3. `deployment/DEPLOYMENT.md` - 部署指南
4. `PROJECT_STRUCTURE.md` - 项目结构

### 部署人员
1. `deployment/DEPLOYMENT_CHECKLIST.md` - 部署检查清单
2. `deployment/DEPLOYMENT_READY.md` - 部署就绪文档
3. `deployment/DOCKER_DEPLOYMENT.md` - Docker部署 (如需要)

### 问题排查
1. `database/ALIYUN_RDS_PERMISSION_ISSUE.md` - 数据库权限问题
2. `deployment/TROUBLESHOOTING_502.md` - 502错误排查
3. `deployment/ERROR_REPORT_502.md` - 错误报告

## 🔧 文档维护

### 更新原则
- 重要变更及时更新相关文档
- 保持文档与代码同步
- 废弃的文档标记为 `(已废弃)`

### 文档规范
- 使用Markdown格式
- 包含清晰的标题和目录
- 提供具体的操作步骤
- 包含必要的代码示例

### 贡献指南
- 新增文档请放入对应分类目录
- 更新文档后请同步更新本索引
- 重要文档请在相应位置标记 ⭐

---

**最后更新**: 2025年10月11日  
**维护者**: 项目团队