# 项目结构说明

## 📁 目录结构

```
旮旯画师之猜猜笔/
│
├── api/                          # API端点（Vercel Serverless）
│   └── db/
│       └── index.js             # 数据库API端点
│
├── database/                     # 数据库相关文件
│   ├── init.sql                 # 完整初始化脚本
│   ├── init_simple.sql          # 简化初始化脚本（推荐）
│   ├── init_aliyun.sql          # 阿里云RDS专用脚本
│   ├── init_user_schema.sql    # 用户Schema脚本
│   ├── MANUAL_SETUP.sql         # 手动设置脚本
│   ├── STEP_BY_STEP_MANUAL.md  # 手动设置指南
│   ├── DATABASE_DESIGN.md       # 数据库设计文档
│   ├── install-psql.md          # PostgreSQL客户端安装指南
│   ├── init-db.js               # Node.js初始化脚本
│   ├── verify-db.js             # 数据验证脚本
│   ├── check-db.js              # 状态检查脚本
│   └── test-app-connection.js   # 应用连接测试脚本
│
├── docs/                         # 项目文档
│   ├── database/                # 数据库文档
│   │   ├── QUICK_START_DB.md                    # 快速启动指南
│   │   ├── APPLICATION_CONNECTION_READY.md      # 应用就绪文档
│   │   ├── DATABASE_INIT_SUCCESS.md             # 初始化成功报告
│   │   ├── DATABASE_CONNECTION_TEST_REPORT.md   # 连接测试报告
│   │   ├── README_DATABASE.md                   # 数据库总览
│   │   ├── ALIYUN_RDS_PERMISSION_ISSUE.md      # 权限问题说明
│   │   └── MANUAL_DATABASE_SETUP.md            # 手动设置文档
│   │
│   ├── deployment/              # 部署文档
│   │   ├── DEPLOYMENT_READY.md          # 部署就绪文档
│   │   ├── DEPLOYMENT_CHECKLIST.md      # 部署检查清单
│   │   ├── DEPLOYMENT.md                # 部署指南
│   │   ├── POSTGREST_DEPLOYMENT.md      # PostgREST部署
│   │   └── SUPABASE_SETUP.md           # Supabase设置
│   │
│   ├── migration/               # 迁移文档
│   │   ├── MIGRATION_CHECK_REPORT.md    # 迁移检查报告
│   │   └── MIGRATION_SUMMARY.md         # 迁移总结
│   │
│   └── PROJECT_STRUCTURE.md     # 本文档
│
├── public/                       # 静态资源
│   ├── cards/                   # 游戏卡片图片
│   │   ├── 662.png
│   │   ├── 663.png
│   │   └── ... (27张卡片)
│   └── vite.svg
│
├── scripts/                      # 工具脚本
│   ├── server-dev.js            # 本地开发API服务器
│   └── test-db-api.html         # API测试页面
│
├── src/                          # 源代码
│   ├── assets/                  # 资源文件
│   │   └── fonts.css
│   │
│   ├── components/              # React组件
│   │   ├── AnswerList.tsx       # 答案列表组件
│   │   ├── CardGallery.tsx      # 卡片画廊组件
│   │   ├── CardZoomModal.tsx    # 卡片放大模态框
│   │   ├── Navigation.tsx       # 导航组件
│   │   ├── StagingArea.tsx      # 暂存区组件
│   │   ├── TextureBackground.tsx # 纹理背景组件
│   │   └── index.ts             # 组件导出
│   │
│   ├── design-system/           # 设计系统
│   │   ├── components/          # 设计系统组件
│   │   ├── tokens/              # 设计令牌
│   │   └── index.ts
│   │
│   ├── lib/                     # 库文件
│   │   └── supabase.ts          # Supabase客户端配置
│   │
│   ├── services/                # API服务
│   │   ├── api.ts               # API服务统一接口
│   │   ├── directDbService.ts   # 直接数据库服务
│   │   ├── postgrestService.ts  # PostgREST服务
│   │   └── supabaseService.ts   # Supabase服务
│   │
│   ├── store/                   # 状态管理
│   │   └── gameStore.ts         # 游戏状态Store
│   │
│   ├── types/                   # TypeScript类型定义
│   │   └── index.ts
│   │
│   ├── utils/                   # 工具函数
│   │   ├── cardUtils.ts         # 卡片工具函数
│   │   ├── localStorage.ts      # 本地存储工具
│   │   ├── mockData.ts          # 模拟数据
│   │   └── touchUtils.ts        # 触摸事件工具
│   │
│   ├── views/                   # 页面视图
│   │   ├── CompletedView.tsx    # 完成页面
│   │   ├── GameView.tsx         # 游戏页面
│   │   ├── LeaderboardView.tsx  # 排行榜页面
│   │   ├── OnboardingView.tsx   # 引导页面
│   │   ├── StatsView.tsx        # 统计页面
│   │   └── index.ts
│   │
│   ├── App.css                  # 应用样式
│   ├── App.tsx                  # 应用主组件
│   ├── index.css                # 全局样式
│   ├── main.tsx                 # 应用入口
│   └── vite-env.d.ts            # Vite类型定义
│
├── supabase/                     # Supabase配置（备用）
│   ├── config.toml
│   └── migrations/
│
├── .dockerignore                 # Docker忽略文件
├── .env                          # 环境变量（不提交到Git）
├── .env.example                  # 环境变量示例
├── .eslintrc.cjs                 # ESLint配置
├── .gitignore                    # Git忽略文件
├── CHANGELOG.md                  # 更新日志
├── deploy.bat                    # Windows部署脚本
├── deploy.sh                     # Linux/Mac部署脚本
├── docker-compose.yml            # Docker Compose配置
├── Dockerfile                    # Docker镜像配置
├── index.html                    # HTML入口
├── LICENSE                       # 许可证
├── mcp.json                      # MCP配置
├── nginx.conf                    # Nginx配置
├── package.json                  # NPM包配置
├── package-lock.json             # NPM锁文件
├── postcss.config.js             # PostCSS配置
├── postgrest.conf                # PostgREST配置
├── README.md                     # 项目说明（主文档）
├── tailwind.config.js            # Tailwind CSS配置
├── tsconfig.json                 # TypeScript配置
├── tsconfig.node.json            # Node TypeScript配置
├── vercel.json                   # Vercel部署配置
└── vite.config.ts                # Vite配置
```

## 📝 文件说明

### 核心配置文件

| 文件 | 说明 |
|------|------|
| `package.json` | NPM包配置，包含依赖和脚本 |
| `vite.config.ts` | Vite构建工具配置 |
| `tsconfig.json` | TypeScript编译配置 |
| `tailwind.config.js` | Tailwind CSS样式配置 |
| `.env` | 环境变量（包含敏感信息，不提交） |
| `vercel.json` | Vercel部署配置 |

### 数据库文件

| 文件 | 用途 |
|------|------|
| `database/init_simple.sql` | **推荐使用**，简化的初始化脚本 |
| `database/init-db.js` | Node.js初始化工具 |
| `database/verify-db.js` | 验证数据库数据 |
| `database/check-db.js` | 检查数据库状态 |
| `database/test-app-connection.js` | 测试应用连接 |

### API服务

| 文件 | 说明 |
|------|------|
| `api/db/index.js` | Vercel Serverless API端点 |
| `scripts/server-dev.js` | 本地开发服务器 |
| `src/services/api.ts` | 前端API服务统一接口 |
| `src/services/directDbService.ts` | 直接数据库服务 |

### 文档文件

| 目录 | 内容 |
|------|------|
| `docs/database/` | 数据库相关文档 |
| `docs/deployment/` | 部署相关文档 |
| `docs/migration/` | 迁移相关文档 |

## 🔄 数据流

```
用户界面 (React)
    ↓
状态管理 (Zustand)
    ↓
API服务层 (src/services/api.ts)
    ↓
    ├─→ DirectDbService (直接连接)
    ├─→ PostgRESTService (PostgREST)
    └─→ SupabaseService (Supabase)
    ↓
API端点 (api/db/index.js 或 scripts/server-dev.js)
    ↓
数据库 (PostgreSQL on 阿里云RDS)
```

## 🎨 组件层次

```
App.tsx
├── OnboardingView (引导页)
├── GameView (游戏页)
│   ├── Navigation
│   ├── CardGallery
│   ├── StagingArea
│   ├── AnswerList
│   └── CardZoomModal
├── CompletedView (完成页)
├── LeaderboardView (排行榜)
└── StatsView (统计页)
```

## 🗄️ 数据库结构

```
数据库: aki
Schema: public
│
├── 表 (Tables)
│   ├── players (玩家表)
│   ├── game_sessions (游戏会话表)
│   └── answer_combinations (答案组合表)
│
├── 视图 (Views)
│   ├── leaderboard (排行榜)
│   └── game_stats (游戏统计)
│
├── 索引 (Indexes)
│   ├── idx_players_nickname
│   ├── idx_game_sessions_player_id
│   ├── idx_game_sessions_score
│   └── idx_answer_combinations_session_id
│
└── 触发器 (Triggers)
    └── update_players_updated_at
```

## 🚀 部署架构

```
用户浏览器
    ↓
Vercel CDN (前端静态资源)
    ↓
Vercel Serverless Functions (API)
    ↓
阿里云RDS PostgreSQL (数据库)
```

## 📦 依赖关系

### 生产依赖
- `react` & `react-dom` - UI框架
- `zustand` - 状态管理
- `@supabase/supabase-js` - Supabase客户端（备用）

### 开发依赖
- `vite` - 构建工具
- `typescript` - 类型系统
- `tailwindcss` - CSS框架
- `eslint` - 代码检查

### 服务器依赖
- `pg` - PostgreSQL客户端
- `express` - Web框架
- `cors` - 跨域支持
- `dotenv` - 环境变量

## 🔐 环境变量

### 数据库配置
```env
DB_HOST=数据库主机
DB_PORT=数据库端口
DB_USER=数据库用户
DB_PASSWORD=数据库密码
DB_NAME=数据库名称
DB_SSL=是否启用SSL
```

### 应用配置
```env
VITE_APP_TITLE=应用标题
VITE_APP_VERSION=应用版本
VITE_USE_DIRECT_DB=是否使用直接数据库连接
```

## 📊 代码统计

- **总文件数**: ~100+
- **代码行数**: ~5000+
- **组件数**: 10+
- **API端点数**: 6
- **数据库表数**: 3
- **文档页数**: 15+

## 🔧 开发工作流

1. **本地开发**
   ```bash
   npm run dev          # 启动前端
   npm run dev:api      # 启动API（可选）
   ```

2. **数据库操作**
   ```bash
   npm run db:init      # 初始化
   npm run db:verify    # 验证
   npm run db:test      # 测试
   ```

3. **构建部署**
   ```bash
   npm run build        # 构建
   npm run deploy       # 部署到Vercel
   ```

## 📚 相关文档

- [主README](../README.md) - 项目概览
- [数据库快速启动](./database/QUICK_START_DB.md) - 数据库配置
- [部署指南](./deployment/DEPLOYMENT.md) - 部署步骤
- [更新日志](../CHANGELOG.md) - 版本历史

---

**文档版本**: 1.0.0  
**最后更新**: 2025-10-10
