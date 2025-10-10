# 旮旯画师项目开发规范

## 项目概述

本项目是一个基于 React + TypeScript 的AI艺术鉴别游戏，采用现代化的前端技术栈和严格的代码质量标准。

## 技术栈规范

### 核心技术
- **前端框架**: React 18 + TypeScript
- **构建工具**: Vite
- **样式方案**: Tailwind CSS + 设计系统
- **状态管理**: Zustand
- **后端**: Node.js + Express + PostgreSQL

### 开发工具
- **代码检查**: ESLint + TypeScript
- **包管理**: npm
- **版本控制**: Git
- **部署**: Vercel (前端) + 阿里云RDS (数据库)

## 文件组织规范

### 目录结构标准
```
src/
├── components/          # 业务组件 (最多8个文件)
├── design-system/       # 设计系统 (强制优先使用)
│   ├── components/      # 设计系统组件
│   ├── tokens/         # 设计令牌
│   └── index.ts        # 统一导出
├── views/              # 页面视图 (最多8个文件)
├── store/              # 状态管理 (最多8个文件)
├── services/           # API服务 (最多8个文件)
├── types/              # TypeScript类型定义
├── utils/              # 工具函数 (最多8个文件)
├── assets/             # 静态资源
└── lib/                # 第三方库配置
```

### 文件命名规范
- **组件文件**: PascalCase (如 `CardGallery.tsx`)
- **工具文件**: camelCase (如 `cardUtils.ts`)
- **类型文件**: camelCase (如 `gameTypes.ts`)
- **常量文件**: UPPER_SNAKE_CASE (如 `API_CONSTANTS.ts`)

## 代码质量标准

### 文件行数限制
- **TypeScript/React 文件**: 最多 200 行
- **工具函数文件**: 最多 150 行
- **类型定义文件**: 最多 100 行

### 组件设计原则
1. **单一职责**: 每个组件只负责一个功能
2. **可复用性**: 优先使用设计系统组件
3. **类型安全**: 严格的 TypeScript 类型定义
4. **性能优化**: 合理使用 React.memo 和 useMemo

### 设计系统强制规范
- **强制要求**: 所有UI组件必须优先使用 `src/design-system/` 中的组件
- **禁止行为**: 绕过设计系统直接编写样式
- **扩展流程**: 需要新组件时，先扩展设计系统，再在业务中使用

## 代码风格规范

### TypeScript 规范
```typescript
// ✅ 正确：明确的接口定义
interface CardGalleryProps {
  className?: string
  onCardZoom?: (card: CardType) => void
}

// ✅ 正确：使用泛型约束
const useGameStore = <T extends GameState>() => {
  // 实现
}

// ❌ 错误：使用 any 类型
const handleClick = (data: any) => {
  // 避免使用 any
}
```

### React 组件规范
```typescript
// ✅ 正确：函数组件 + TypeScript
export const CardGallery: React.FC<CardGalleryProps> = ({ 
  className = '', 
  onCardZoom 
}) => {
  // 组件逻辑
}

// ✅ 正确：使用设计系统组件
import { Card, Button } from '../design-system'

// ❌ 错误：直接使用原生HTML + 内联样式
<div style={{ padding: '16px' }}>
```

### 状态管理规范
```typescript
// ✅ 正确：Zustand store 结构
interface GameStore {
  // 状态
  gameState: GameState
  selectedCards: Card[]
  
  // 动作
  addSelectedCard: (card: Card) => void
  resetGame: () => void
}

// ✅ 正确：不可变更新
addSelectedCard: (card) => 
  set((state) => ({
    selectedCards: [...state.selectedCards, card]
  }))
```

## 性能优化规范

### 组件优化
- 使用 `React.memo` 包装纯组件
- 合理使用 `useMemo` 和 `useCallback`
- 避免在渲染函数中创建对象和函数

### 资源优化
- 图片使用 WebP 格式
- 实现懒加载和虚拟滚动
- 代码分割和动态导入

## 测试规范

### 测试覆盖要求
- 工具函数: 100% 覆盖率
- 组件逻辑: 80% 覆盖率
- 状态管理: 90% 覆盖率

### 测试文件命名
- 单元测试: `*.test.ts` 或 `*.test.tsx`
- 集成测试: `*.integration.test.ts`

## Git 提交规范

### 提交信息格式
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### 提交类型
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建工具或辅助工具的变动

### 示例
```
feat(game): 添加卡片缩放功能

- 实现卡片点击放大预览
- 添加关闭按钮和键盘ESC支持
- 优化移动端触摸体验

Closes #123
```

## 部署规范

### 环境配置
- **开发环境**: 本地开发 + 测试数据库
- **预发布环境**: Vercel Preview + 测试数据库
- **生产环境**: Vercel Production + 阿里云RDS

### 部署检查清单
- [ ] TypeScript 编译通过
- [ ] ESLint 检查通过
- [ ] 单元测试通过
- [ ] 构建成功
- [ ] 环境变量配置正确
- [ ] 数据库连接测试通过

## 代码审查规范

### 审查要点
1. **架构设计**: 是否符合项目架构原则
2. **代码质量**: 是否存在代码坏味道
3. **性能影响**: 是否有性能问题
4. **安全考虑**: 是否存在安全隐患
5. **测试覆盖**: 是否有足够的测试

### 必须检查的代码坏味道
- **僵化**: 修改一处需要改动多处
- **冗余**: 重复的代码逻辑
- **循环依赖**: 模块间的循环引用
- **脆弱性**: 修改导致意外破坏
- **晦涩性**: 代码意图不明确
- **数据泥团**: 相同参数组合重复出现
- **过度复杂**: 简单问题复杂化

## 文档规范

### 必需文档
- **README.md**: 项目介绍和快速开始
- **API文档**: 接口说明和示例
- **组件文档**: 设计系统组件使用说明
- **部署文档**: 部署步骤和配置说明

### 代码注释规范
```typescript
/**
 * 卡片画廊组件
 * 
 * @description 展示可选择的卡片列表，支持横向滚动和卡片选择
 * @param className - 自定义样式类名
 * @param onCardZoom - 卡片放大回调函数
 */
export const CardGallery: React.FC<CardGalleryProps> = ({
  className = '',
  onCardZoom
}) => {
  // 组件实现
}
```

## 安全规范

### 前端安全
- 输入验证和转义
- XSS 防护
- CSRF 防护
- 敏感信息不在前端存储

### API 安全
- 参数验证
- SQL 注入防护
- 访问控制
- 错误信息不泄露敏感数据

## 监控和日志

### 错误监控
- 前端错误捕获和上报
- API 错误日志记录
- 性能监控和分析

### 日志规范
```typescript
// ✅ 正确：结构化日志
logger.info('Card selected', {
  cardId: card.id,
  userId: user.id,
  timestamp: Date.now()
})

// ❌ 错误：非结构化日志
console.log('用户选择了卡片')
```

## 持续改进

### 定期检查
- 每月代码质量审查
- 每季度架构评估
- 每半年技术栈更新评估

### 指标监控
- 代码覆盖率
- 构建时间
- 包大小
- 页面加载性能
- 用户体验指标

---

**重要提醒**: 
- 严格遵守文件行数和目录结构限制
- 强制使用设计系统，禁止绕过
- 发现代码坏味道立即重构
- 保持代码简洁和可维护性