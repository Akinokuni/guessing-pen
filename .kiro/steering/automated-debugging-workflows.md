# 自动化调试工作流

## 概述

本文档记录了使用MCP工具自动获取和分析错误信息的工作流程。

## 工作流1: 自动获取GitHub Actions错误

### 使用场景
当GitHub Actions构建失败时，自动浏览Actions页面获取详细错误信息。

### 工具要求
- `chrome-devtools-mcp`: 用于浏览器自动化

### 操作步骤

#### 1. 导航到GitHub Actions页面
```
使用工具: mcp_chrome_devtools_navigate_page
参数:
  - url: https://github.com/{username}/{repo}/actions
  - timeout: 10000
```

#### 2. 等待页面加载
```
使用工具: mcp_chrome_devtools_take_snapshot
目的: 获取页面内容快照，查看工作流运行列表
```

#### 3. 识别失败的工作流
从快照中查找：
- 状态为 "failed" 的工作流
- 最新的运行记录
- 相关的错误标记

#### 4. 点击失败的工作流
```
使用工具: mcp_chrome_devtools_click
参数:
  - uid: {失败工作流的元素ID}
```

#### 5. 等待详情页面加载
```
使用工具: mcp_chrome_devtools_wait_for
参数:
  - text: {工作流名称或提交信息}
  - timeout: 5000
```

#### 6. 获取错误详情
从详情页面提取：
- 失败的Job名称
- 具体的错误信息
- 失败的步骤
- 错误代码和消息

### 完整示例

```typescript
// 步骤1: 导航到Actions页面
await mcp_chrome_devtools_navigate_page({
  url: "https://github.com/Akinokuni/guessing-pen/actions",
  timeout: 10000
});

// 步骤2: 获取页面快照
const snapshot = await mcp_chrome_devtools_take_snapshot();

// 步骤3: 从快照中找到失败的工作流
// 查找包含 "failed:" 的链接元素

// 步骤4: 点击失败的工作流
await mcp_chrome_devtools_click({
  uid: "1_120" // 失败工作流的UID
});

// 步骤5: 等待详情页面
await mcp_chrome_devtools_wait_for({
  text: "docs: 添加CI工作流状态说明文档",
  timeout: 5000
});

// 步骤6: 获取错误信息
// 从页面中提取 "Annotations" 部分的错误信息
```

### 提取的关键信息

从GitHub Actions页面可以获取：

1. **工作流状态**
   - 工作流名称
   - 运行编号
   - 触发方式（push/pull_request）
   - 提交哈希和分支

2. **Job状态**
   - 成功的Jobs ✅
   - 失败的Jobs ❌
   - 每个Job的执行时间

3. **错误详情**
   - 错误消息
   - 失败的步骤
   - 错误代码
   - 堆栈跟踪（如果有）

4. **构建产物**
   - Artifacts列表
   - 文件大小
   - 下载链接

### 实际案例

**场景**: ACR推送失败

**获取到的错误信息**:
```
Error response from daemon: Get "https://crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/v2/": 
unauthorized: authentication required
```

**分析结果**:
- 失败步骤: "构建并推送镜像"
- 成功步骤: "代码检查和测试"
- 根本原因: ACR认证失败
- 解决方案: 配置GitHub Secrets

## 工作流2: 自动分析构建日志

### 使用场景
深入分析失败Job的详细日志。

### 操作步骤

1. 在工作流详情页面点击失败的Job
2. 展开失败的步骤
3. 提取完整的日志输出
4. 分析错误模式和堆栈跟踪

### 工具使用
```
使用工具: mcp_chrome_devtools_click
目的: 点击失败的Job展开详情

使用工具: mcp_chrome_devtools_take_snapshot
目的: 获取日志内容
```

## 工作流3: 自动检查多个工作流

### 使用场景
项目有多个工作流时，批量检查状态。

### 操作步骤

1. 获取所有工作流列表
2. 过滤失败的工作流
3. 逐个点击查看详情
4. 汇总所有错误信息

### 自动化脚本模式

```bash
# 伪代码示例
for workflow in failed_workflows:
    navigate_to(workflow.url)
    error_info = extract_error_details()
    save_to_memory(error_info)
    generate_fix_suggestions(error_info)
```

## 工作流4: 错误信息持久化

### 使用场景
将获取的错误信息保存到项目文档中。

### 操作步骤

1. 从浏览器获取错误信息
2. 分析错误类型和原因
3. 生成结构化的错误报告
4. 保存到 `.kiro/steering/github-actions-issues.md`
5. 提交到Git仓库

### 文档结构

```markdown
## 问题X: [问题标题]

### 错误信息
[原始错误消息]

### 问题分析
- 工作流: [名称]
- 失败步骤: [步骤名]
- 根本原因: [分析]

### 解决方案
[具体的修复步骤]

### 状态
- 当前: [状态]
- 计划: [后续行动]
```

## 最佳实践

### 1. 自动化触发时机
- CI/CD失败时自动运行
- 定期健康检查
- 手动触发调试

### 2. 错误分类
- 构建错误
- 测试失败
- 部署问题
- 配置错误

### 3. 优先级判断
- 🔴 阻塞性错误：立即修复
- 🟡 警告：计划修复
- 🟢 信息：记录备查

### 4. 反馈循环
```
发现错误 → 自动获取详情 → 分析原因 → 生成方案 → 应用修复 → 验证结果
```

## 工具链集成

### Chrome DevTools MCP功能
- `navigate_page`: 导航到指定URL
- `take_snapshot`: 获取页面内容快照
- `click`: 点击页面元素
- `wait_for`: 等待特定内容出现
- `take_screenshot`: 截图保存证据

### 与其他工具配合
- **Git**: 提交错误报告和修复
- **文件系统**: 保存日志和截图
- **通知系统**: 发送告警（未来）

## 维护和改进

### 定期更新
- [ ] 每月审查自动化流程
- [ ] 优化错误识别模式
- [ ] 扩展支持的错误类型
- [ ] 改进错误分析算法

### 扩展计划
- 支持更多CI/CD平台
- 自动生成修复PR
- 集成AI分析错误
- 建立错误知识库

---

**创建日期**: 2025-10-11  
**维护者**: Kiro AI Assistant  
**版本**: 1.0.0