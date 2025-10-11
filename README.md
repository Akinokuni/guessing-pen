# 旮旯画师之猜猜笔 🎨

一个有趣的AI艺术鉴别游戏，挑战你识别人类创作和AI生成作品的能力。

🚀 **现已支持完整的自动化部署流程！**

## 🎮 游戏介绍

在这个游戏中，你需要：
1. **分组挑战**：将27张卡片按规则分成9组，每组3张
2. **AI鉴别**：在每组中标记出AI生成的作品
3. **获得分数**：根据分组准确度和AI识别能力获得分数

### 计分规则
- **分组得分**（满分70分）：每个完美分组8分，全部正确70分
- **AI鉴别得分**（满分30分）：正确识别+7.5分，误判-3分
- **总分**：最高100分

## 🚀 快速开始

### 安装依赖
```bash
npm install
```

### 开发环境
```bash
# 启动前端开发服务器
npm run dev

# 启动API开发服务器（需要先配置数据库）
npm run dev:api
```

### 数据库设置
```bash
# 初始化数据库
npm run db:init

# 验证数据库
npm run db:verify

# 测试连接
npm run db:test
```

详细的数据库配置请查看：[数据库快速启动指南](./docs/database/QUICK_START_DB.md)

### 构建生产版本
```bash
npm run build
```

## 📁 项目结构

```
.
├── api/                    # API端点
│   └── db/                # 数据库API
├── database/              # 数据库脚本
│   ├── init-db.js        # 初始化脚本
│   ├── verify-db.js      # 验证脚本
│   └── *.sql             # SQL脚本
├── docs/                  # 文档
│   ├── database/         # 数据库文档
│   ├── deployment/       # 部署文档
│   └── migration/        # 迁移文档
├── public/               # 静态资源
│   └── cards/           # 游戏卡片图片
├── scripts/              # 工具脚本
│   ├── server-dev.js    # 开发服务器
│   └── test-db-api.html # API测试页面
├── src/                  # 源代码
│   ├── components/      # React组件
│   ├── services/        # API服务
│   ├── store/          # 状态管理
│   ├── types/          # TypeScript类型
│   ├── utils/          # 工具函数
│   └── views/          # 页面视图
└── supabase/            # Supabase配置（备用）
```

## 🛠️ 技术栈

### 前端
- **React 18** - UI框架
- **TypeScript** - 类型安全
- **Vite** - 构建工具
- **Tailwind CSS** - 样式框架
- **Zustand** - 状态管理

### 后端
- **PostgreSQL** - 数据库（阿里云RDS）
- **Node.js** - API服务器
- **Express** - Web框架
- **pg** - PostgreSQL客户端

### 部署
- **Vercel** - 前端托管
- **阿里云RDS** - 数据库托管

## 📚 文档

### 数据库
- [快速启动指南](./docs/database/QUICK_START_DB.md) - 最简单的开始方式
- [数据库就绪文档](./docs/database/APPLICATION_CONNECTION_READY.md) - 完整配置指南
- [初始化成功报告](./docs/database/DATABASE_INIT_SUCCESS.md) - 初始化详情
- [连接测试报告](./docs/database/DATABASE_CONNECTION_TEST_REPORT.md) - 测试结果
- [数据库设计](./database/DATABASE_DESIGN.md) - 表结构设计

### 部署
- [部署就绪文档](./docs/deployment/DEPLOYMENT_READY.md) - 部署准备
- [部署检查清单](./docs/deployment/DEPLOYMENT_CHECKLIST.md) - 部署步骤
- [Vercel部署指南](./docs/deployment/DEPLOYMENT.md) - Vercel配置

### 迁移
- [迁移检查报告](./docs/migration/MIGRATION_CHECK_REPORT.md) - 迁移状态
- [迁移总结](./docs/migration/MIGRATION_SUMMARY.md) - 迁移详情

## 🔧 配置

### 环境变量

创建 `.env` 文件：

```env
# 数据库配置
DB_HOST=your-database-host
DB_PORT=5432
DB_USER=your-username
DB_PASSWORD=your-password
DB_NAME=your-database
DB_SSL=false

# 应用配置
VITE_APP_TITLE=旮旯画师之猜猜笔
VITE_APP_VERSION=1.0.0
VITE_USE_DIRECT_DB=true
```

### 阿里云RDS白名单

要使API正常工作，需要配置RDS白名单：
1. 登录阿里云RDS控制台
2. 找到你的数据库实例
3. 进入"数据安全性" → "白名单设置"
4. 添加你的IP地址或 `0.0.0.0/0`（测试用）

详细步骤请查看：[数据库快速启动指南](./docs/database/QUICK_START_DB.md)

## 🧪 测试

### 数据库测试
```bash
# 检查数据库状态
npm run db:check

# 验证数据
npm run db:verify

# 测试连接
npm run db:test
```

### API测试
启动开发服务器后，访问：
```
http://localhost:3001/scripts/test-db-api.html
```

## 📦 NPM脚本

### 开发
- `npm run dev` - 启动前端开发服务器
- `npm run dev:api` - 启动API开发服务器

### 构建
- `npm run build` - 构建生产版本
- `npm run build:skip-check` - 跳过类型检查构建
- `npm run preview` - 预览生产构建

### 数据库
- `npm run db:init` - 初始化数据库
- `npm run db:verify` - 验证数据库数据
- `npm run db:check` - 检查数据库状态
- `npm run db:test` - 测试应用连接

### Docker
- `npm run docker:build` - 构建Docker镜像
- `npm run docker:run` - 运行Docker容器
- `npm run docker:stop` - 停止Docker容器
- `npm run docker:logs` - 查看Docker日志

### 部署
- `npm run deploy` - 部署到Vercel

## 🎯 游戏规则

### 分组规则
27张卡片需要按照特定规则分成9组，每组3张。正确的分组方式只有一种。

### AI识别
每组中有一张是AI生成的作品，你需要准确识别出来。

### 得分系统
- **完美分组**：所有9组都正确 = 70分
- **部分分组**：每个正确的组 = 8分
- **AI识别**：每次正确识别 = +7.5分
- **误判惩罚**：每次错误标记 = -3分

## 🤝 贡献

欢迎提交问题和拉取请求！

## 📄 许可证

MIT License

## 🔗 相关链接

- [在线演示](https://your-app.vercel.app)
- [问题反馈](https://github.com/your-repo/issues)
- [更新日志](./CHANGELOG.md)

## 📞 支持

遇到问题？
1. 查看 [文档目录](./docs/)
2. 运行 `npm run db:check` 检查数据库
3. 查看 [故障排查指南](./docs/database/QUICK_START_DB.md#故障排查)

---

**Made with ❤️ for the Galgame Community**
