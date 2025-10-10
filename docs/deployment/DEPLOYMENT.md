# 部署指南

## 🚀 Vercel 部署（推荐）

### 前置条件
- GitHub 账号
- Vercel 账号

### 部署步骤

1. **准备代码仓库**
   ```bash
   # 初始化 Git 仓库
   git init
   git add .
   git commit -m "Initial commit"
   
   # 推送到 GitHub
   git remote add origin https://github.com/your-username/guessing-pen-challenge.git
   git push -u origin main
   ```

2. **Vercel 部署**
   - 访问 [vercel.com](https://vercel.com)
   - 点击 "New Project"
   - 导入 GitHub 仓库
   - 配置项目设置：
     - Framework Preset: Vite
     - Build Command: `npm run build`
     - Output Directory: `dist`
   - 点击 "Deploy"

3. **环境变量配置**（如果需要）
   在 Vercel 项目设置中添加环境变量：
   ```
   VITE_SUPABASE_URL=your_supabase_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

## 🐳 Docker 部署

### 使用现有 Docker 配置

1. **构建镜像**
   ```bash
   docker build -t guessing-pen-challenge:latest .
   ```

2. **运行容器**
   ```bash
   docker run -p 80:80 guessing-pen-challenge:latest
   ```

3. **使用 Docker Compose**
   ```bash
   docker-compose up -d
   ```

## 📦 静态文件部署

### 构建生产版本
```bash
npm install
npm run build
```

### 部署到静态托管服务
构建完成后，将 `dist` 文件夹的内容上传到：
- Netlify
- GitHub Pages
- AWS S3
- 阿里云 OSS
- 腾讯云 COS

## 🔧 配置说明

### 必要文件检查清单
- [x] `package.json` - 项目依赖和脚本
- [x] `vite.config.ts` - Vite 构建配置
- [x] `tsconfig.json` - TypeScript 配置
- [x] `tailwind.config.js` - Tailwind CSS 配置
- [x] `vercel.json` - Vercel 部署配置
- [x] `src/` - 源代码目录
- [x] `public/` - 静态资源目录
- [x] `api/` - API 路由（Vercel Functions）

### 环境变量
创建 `.env` 文件（基于 `.env.example`）：
```env
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 🔍 部署验证

部署完成后，验证以下功能：
- [ ] 页面正常加载
- [ ] 卡片图片显示正常
- [ ] 游戏交互功能正常
- [ ] API 接口响应正常
- [ ] 移动端适配正常

## 🐛 常见问题

### 1. 卡片图片不显示
- 检查 `public/cards/` 目录是否包含所有卡片图片
- 确认图片路径配置正确

### 2. API 接口 404 错误
- 检查 `vercel.json` 配置
- 确认 `api/` 目录结构正确

### 3. 构建失败
- 检查 Node.js 版本（需要 18+）
- 清除缓存：`rm -rf node_modules package-lock.json && npm install`

### 4. TypeScript 错误
- 运行类型检查：`npm run build`
- 检查 `tsconfig.json` 配置

## 📞 技术支持

如遇到部署问题，请检查：
1. 控制台错误信息
2. 网络请求状态
3. 环境变量配置
4. 构建日志输出

---

**部署版本**: 1.0.0  
**最后更新**: 2024年12月