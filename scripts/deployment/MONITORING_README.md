# 监控和日志系统使用指南

## 概述

本监控和日志系统为Docker + 阿里云ACR + GitHub Actions自动化部署提供完整的监控、日志收集和通知功能。

## 系统组件

### 1. 日志记录工具 (`logger.sh`)
提供统一的日志记录功能，支持不同级别的日志输出和文件记录。

**功能特性**:
- 彩色日志输出
- 文件日志记录
- 日志级别控制
- 自动日志轮转

**使用方法**:
```bash
source scripts/deployment/logger.sh

log_info "这是信息日志"
log_success "这是成功日志"
log_warning "这是警告日志"
log_error "这是错误日志"
log_debug "这是调试日志"  # 需要设置DEBUG=true
```

### 2. 部署状态跟踪器 (`deployment-tracker.sh`)
跟踪部署过程的每个步骤，记录部署历史和状态信息。

**功能特性**:
- 部署过程跟踪
- 步骤状态记录
- 错误和警告收集
- 部署历史管理

**使用方法**:
```bash
# 开始部署跟踪
DEPLOYMENT_ID=$(start_deployment_tracking "v1.0.0" "production" "auto")

# 更新步骤状态
update_deployment_step "build" "success" "构建完成" 30

# 添加错误
add_deployment_error "构建失败" "build"

# 完成部署跟踪
finish_deployment_tracking "success" 120

# 查看部署状态
./deployment-tracker.sh status

# 查看部署历史
./deployment-tracker.sh history 10
```

### 3. 健康检查监控 (`health-monitor.sh`)
监控应用服务的健康状态，包括前端、API和数据库服务。

**功能特性**:
- HTTP服务健康检查
- API端点健康检查
- 数据库连接检查
- 持续健康监控
- 服务就绪等待

**使用方法**:
```bash
# 执行一次健康检查
./health-monitor.sh check

# 查看健康状态
./health-monitor.sh status

# 持续监控 (每60秒检查，3次失败后告警)
./health-monitor.sh monitor 60 3

# 等待服务就绪 (最多300秒，每10秒检查)
./health-monitor.sh wait 300 10
```

### 4. 通知系统 (`notification-system.sh`)
发送部署状态通知到各种通道，如Webhook、Slack、钉钉等。

**功能特性**:
- 多通道通知支持
- 模板化消息
- 通知配置管理
- 失败重试机制

**使用方法**:
```bash
# 初始化通知系统
./notification-system.sh init

# 测试通知系统
./notification-system.sh test

# 发送部署开始通知
./notification-system.sh start v1.0.0 production main abc123 "User"

# 发送部署成功通知
./notification-system.sh success v1.0.0 production 120 "https://example.com"

# 发送部署失败通知
./notification-system.sh failure v1.0.0 production build "Build failed" "/logs/deploy.log"
```

### 5. 日志收集器 (`log-collector.sh`)
收集和管理容器日志，提供日志分析和导出功能。

**功能特性**:
- 容器日志收集
- 日志分析统计
- 日志轮转压缩
- 日志导出功能
- 实时日志监控

**使用方法**:
```bash
# 初始化日志收集系统
./log-collector.sh init

# 收集所有容器日志 (最近1小时)
./log-collector.sh collect 1h

# 分析API服务日志
./log-collector.sh analyze api 1d

# 轮转API服务日志
./log-collector.sh rotate api

# 压缩7天前的日志
./log-collector.sh compress 7

# 实时监控API容器的错误日志
./log-collector.sh monitor guessing-pen-api ERROR

# 获取日志统计信息
./log-collector.sh stats
```

### 6. 集成监控系统 (`monitoring-system.sh`)
集成所有监控组件的主控制脚本，提供统一的监控服务。

**功能特性**:
- 集成健康检查
- 集成日志收集
- 系统指标收集
- 后台监控服务
- 统一配置管理

**使用方法**:
```bash
# 初始化监控系统
./monitoring-system.sh init

# 启动监控系统
./monitoring-system.sh start

# 查看监控状态
./monitoring-system.sh status

# 停止监控系统
./monitoring-system.sh stop

# 重启监控系统
./monitoring-system.sh restart
```

## 配置文件

### 1. 通知配置 (`.github/deployment/notification-config.json`)
```json
{
  "enabled": true,
  "channels": {
    "webhook": {
      "enabled": false,
      "url": "",
      "timeout": 30,
      "retries": 3
    },
    "slack": {
      "enabled": false,
      "webhook_url": "",
      "channel": "#deployments",
      "username": "DeployBot"
    },
    "dingtalk": {
      "enabled": false,
      "webhook_url": "",
      "secret": ""
    }
  },
  "events": {
    "deployment_start": true,
    "deployment_success": true,
    "deployment_failure": true,
    "health_check_failure": true
  }
}
```

### 2. 日志收集配置 (`logs/log-collection-config.json`)
```json
{
  "enabled": true,
  "collection": {
    "interval": 60,
    "maxLogSize": "100M",
    "maxLogFiles": 10,
    "rotationInterval": "daily"
  },
  "containers": {
    "frontend": {
      "name": "guessing-pen-frontend",
      "enabled": true,
      "logLevel": "info"
    },
    "api": {
      "name": "guessing-pen-api",
      "enabled": true,
      "logLevel": "info"
    }
  }
}
```

### 3. 监控系统配置 (`logs/monitoring-config.json`)
```json
{
  "enabled": true,
  "intervals": {
    "healthCheck": 60,
    "logCollection": 300,
    "systemMetrics": 120
  },
  "thresholds": {
    "healthCheckFailures": 3,
    "responseTimeWarning": 2000,
    "responseTimeError": 5000,
    "memoryUsageWarning": 80,
    "memoryUsageError": 90
  }
}
```

## 环境变量

### 必需的环境变量
```bash
# 服务配置
FRONTEND_HOST=localhost
FRONTEND_PORT=80
API_HOST=localhost
API_PORT=3005

# 容器名称
FRONTEND_CONTAINER_NAME=guessing-pen-frontend
API_CONTAINER_NAME=guessing-pen-api

# 通知配置
HEALTH_ALERT_WEBHOOK=https://your-webhook-url

# 调试模式
DEBUG=false
```

## 目录结构

```
logs/
├── deployments/           # 部署状态和历史
│   ├── history.json      # 部署历史记录
│   └── current.json      # 当前部署状态
├── containers/           # 容器日志
│   ├── frontend/         # 前端容器日志
│   ├── api/             # API容器日志
│   ├── database/        # 数据库容器日志
│   └── archived/        # 归档日志
├── health-status.json   # 健康检查状态
├── monitoring-config.json # 监控配置
├── monitoring-status.json # 监控状态
└── system-metrics.json  # 系统指标
```

## 使用场景

### 1. 部署过程监控
```bash
# 在部署脚本中集成监控
source scripts/deployment/logger.sh
source scripts/deployment/deployment-tracker.sh
source scripts/deployment/notification-system.sh

# 开始部署
DEPLOYMENT_ID=$(start_deployment_tracking "v1.0.0" "production")
notify_deployment_start "v1.0.0" "production" "main" "abc123" "User"

# 执行部署步骤...
update_deployment_step "build" "success" "构建完成" 30

# 完成部署
finish_deployment_tracking "success" 120
notify_deployment_success "v1.0.0" "production" 120 "https://app.com"
```

### 2. 持续健康监控
```bash
# 启动后台健康监控
./health-monitor.sh monitor 60 3 &

# 或使用集成监控系统
./monitoring-system.sh start
```

### 3. 日志管理
```bash
# 定期收集日志
./log-collector.sh collect 1h

# 分析日志问题
./log-collector.sh analyze api 1d

# 清理旧日志
./log-collector.sh rotate api
./log-collector.sh compress 7
```

### 4. 故障排查
```bash
# 查看当前健康状态
./health-monitor.sh status

# 查看部署历史
./deployment-tracker.sh history

# 查看最新日志
./log-collector.sh monitor guessing-pen-api

# 查看系统指标
./monitoring-system.sh status
```

## 集成到CI/CD

监控和日志系统已集成到GitHub Actions工作流中：

1. **部署开始**: 自动发送通知并开始跟踪
2. **步骤监控**: 每个部署步骤都会被记录和监控
3. **健康检查**: 部署后自动执行健康检查
4. **日志收集**: 部署完成后收集容器日志
5. **通知发送**: 根据部署结果发送成功或失败通知

## 故障排查

### 常见问题

1. **脚本权限问题**
   ```bash
   # Linux/macOS
   chmod +x scripts/deployment/*.sh
   
   # Windows (PowerShell)
   # 脚本会自动处理权限问题
   ```

2. **jq命令未找到**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # CentOS/RHEL
   sudo yum install jq
   
   # macOS
   brew install jq
   ```

3. **Docker命令权限问题**
   ```bash
   # 将用户添加到docker组
   sudo usermod -aG docker $USER
   ```

4. **通知发送失败**
   - 检查网络连接
   - 验证Webhook URL
   - 检查认证信息

### 日志文件位置

- 部署日志: `logs/deployment-*.log`
- 健康检查日志: `logs/health-*.log`
- 容器日志: `logs/containers/*/`
- 系统日志: `logs/system-*.log`

## 最佳实践

1. **定期检查**: 每天检查监控状态和日志
2. **配置告警**: 设置合适的告警阈值
3. **日志轮转**: 定期清理旧日志文件
4. **备份配置**: 备份重要的配置文件
5. **测试通知**: 定期测试通知系统
6. **监控指标**: 关注关键性能指标

## 支持和维护

- 监控系统会自动处理大部分日常维护任务
- 定期更新配置以适应新的需求
- 监控系统性能，确保不影响应用性能
- 根据实际使用情况调整阈值和间隔

---

**版本**: 1.0.0  
**最后更新**: 2025年10月11日  
**维护者**: Kiro AI Assistant