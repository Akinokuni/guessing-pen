# 脚本书写规范

## 脚本分类和组织

### 📁 目录结构规范
```
scripts/
├── deployment/         # 部署相关脚本
├── testing/           # 测试和诊断脚本
├── development/       # 开发辅助脚本
├── maintenance/       # 维护和清理脚本
├── utils/            # 通用工具脚本
└── README.md         # 脚本索引 (必需)
```

### 📋 脚本命名规范

#### 命名原则
- 使用小写字母和连字符，采用 kebab-case 格式
- 脚本名应清晰表达功能和用途
- 包含动作词，如 deploy、test、build、clean

#### 命名模式
```bash
# 部署脚本
deploy-[环境].sh              # 部署到指定环境
docker-deploy.sh              # Docker部署
clean-and-deploy.sh           # 清理后部署

# 测试脚本
test-[功能].sh               # 测试特定功能
diagnose-[服务].sh           # 诊断特定服务
check-[状态].sh              # 检查状态

# 开发脚本
server-dev.js                # 开发服务器
build-[类型].sh              # 构建脚本
watch-[资源].sh              # 监控脚本

# 维护脚本
clean-[资源].sh              # 清理脚本
backup-[数据].sh             # 备份脚本
update-[组件].sh             # 更新脚本
```

## Shell脚本规范

### 📝 脚本头部模板
```bash
#!/bin/bash

#==============================================================================
# 脚本名称: deploy-production.sh
# 脚本描述: 部署应用到生产环境
# 作者: [作者姓名]
# 创建日期: 2025-10-11
# 最后修改: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly LOG_FILE="${PROJECT_ROOT}/logs/deploy-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color
```

### 🔧 函数定义规范
```bash
#==============================================================================
# 日志和输出函数
#==============================================================================

# 打印信息日志
log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

# 打印成功日志
log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

# 打印警告日志
log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

# 打印错误日志并退出
log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
    exit 1
}

#==============================================================================
# 工具函数
#==============================================================================

# 检查命令是否存在
check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_error "命令 '${cmd}' 未找到，请先安装"
    fi
}

# 检查文件是否存在
check_file() {
    local file="$1"
    if [[ ! -f "${file}" ]]; then
        log_error "文件 '${file}' 不存在"
    fi
}

# 检查目录是否存在
check_directory() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        log_error "目录 '${dir}' 不存在"
    fi
}

# 确认操作
confirm_action() {
    local message="$1"
    echo -e "${YELLOW}${message}${NC}"
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
}
```

### 🚀 主要功能实现
```bash
#==============================================================================
# 主要功能函数
#==============================================================================

# 环境检查
check_environment() {
    log_info "检查环境..."
    
    # 检查必需的命令
    check_command "node"
    check_command "npm"
    check_command "git"
    
    # 检查必需的文件
    check_file "${PROJECT_ROOT}/package.json"
    check_file "${PROJECT_ROOT}/.env.production"
    
    # 检查Node.js版本
    local node_version
    node_version=$(node --version | cut -d'v' -f2)
    log_info "Node.js版本: ${node_version}"
    
    log_success "环境检查完成"
}

# 构建应用
build_application() {
    log_info "开始构建应用..."
    
    cd "${PROJECT_ROOT}"
    
    # 安装依赖
    log_info "安装依赖..."
    npm ci --production=false
    
    # 运行构建
    log_info "运行构建..."
    npm run build
    
    # 检查构建结果
    if [[ ! -d "dist" ]]; then
        log_error "构建失败：dist目录不存在"
    fi
    
    log_success "应用构建完成"
}

# 部署应用
deploy_application() {
    log_info "开始部署应用..."
    
    # 这里添加具体的部署逻辑
    # 例如：上传文件、重启服务等
    
    log_success "应用部署完成"
}
```

### 📋 主函数和错误处理
```bash
#==============================================================================
# 错误处理
#==============================================================================

# 清理函数
cleanup() {
    log_info "执行清理操作..."
    # 在这里添加清理逻辑
}

# 错误处理函数
error_handler() {
    local line_number="$1"
    log_error "脚本在第 ${line_number} 行发生错误"
    cleanup
    exit 1
}

# 设置错误处理
trap 'error_handler ${LINENO}' ERR
trap cleanup EXIT

#==============================================================================
# 主函数
#==============================================================================

main() {
    log_info "开始执行部署脚本..."
    
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # 确认操作
    confirm_action "即将部署到生产环境，这将影响线上服务。"
    
    # 执行主要步骤
    check_environment
    build_application
    deploy_application
    
    log_success "部署脚本执行完成！"
    log_info "日志文件: ${LOG_FILE}"
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help      显示此帮助信息
    -v, --verbose   详细输出模式
    -d, --dry-run   试运行模式（不执行实际操作）

示例:
    $0                  # 正常部署
    $0 --dry-run        # 试运行
    $0 --verbose        # 详细输出

EOF
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "未知参数: $1"
            ;;
    esac
done

# 执行主函数
main "$@"
```

## Node.js脚本规范

### 📝 脚本头部模板
```javascript
#!/usr/bin/env node

/**
 * 脚本名称: server-dev.js
 * 脚本描述: 开发环境API服务器
 * 作者: [作者姓名]
 * 创建日期: 2025-10-11
 * 最后修改: 2025-10-11
 * 版本: 1.0.0
 */

'use strict';

// 导入必需的模块
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');

// 配置常量
const CONFIG = {
    PORT: process.env.PORT || 3001,
    HOST: process.env.HOST || 'localhost',
    NODE_ENV: process.env.NODE_ENV || 'development',
    LOG_LEVEL: process.env.LOG_LEVEL || 'info'
};

// 日志工具
const logger = {
    info: (message, ...args) => {
        console.log(`[INFO] ${new Date().toISOString()} - ${message}`, ...args);
    },
    warn: (message, ...args) => {
        console.warn(`[WARN] ${new Date().toISOString()} - ${message}`, ...args);
    },
    error: (message, ...args) => {
        console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, ...args);
    },
    success: (message, ...args) => {
        console.log(`[SUCCESS] ${new Date().toISOString()} - ${message}`, ...args);
    }
};
```

### 🔧 工具函数
```javascript
/**
 * 检查文件是否存在
 * @param {string} filePath - 文件路径
 * @returns {boolean} 文件是否存在
 */
function fileExists(filePath) {
    try {
        return fs.statSync(filePath).isFile();
    } catch (error) {
        return false;
    }
}

/**
 * 读取JSON配置文件
 * @param {string} configPath - 配置文件路径
 * @returns {Object} 配置对象
 */
function loadConfig(configPath) {
    try {
        if (!fileExists(configPath)) {
            throw new Error(`配置文件不存在: ${configPath}`);
        }
        
        const configContent = fs.readFileSync(configPath, 'utf8');
        return JSON.parse(configContent);
    } catch (error) {
        logger.error(`加载配置文件失败: ${error.message}`);
        process.exit(1);
    }
}

/**
 * 优雅关闭处理
 * @param {Object} server - Express服务器实例
 */
function setupGracefulShutdown(server) {
    const shutdown = (signal) => {
        logger.info(`收到 ${signal} 信号，开始优雅关闭...`);
        
        server.close((error) => {
            if (error) {
                logger.error('服务器关闭时发生错误:', error);
                process.exit(1);
            }
            
            logger.success('服务器已优雅关闭');
            process.exit(0);
        });
        
        // 强制关闭超时
        setTimeout(() => {
            logger.error('强制关闭服务器');
            process.exit(1);
        }, 10000);
    };
    
    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));
}
```

### 🚀 主要功能实现
```javascript
/**
 * 创建Express应用
 * @returns {Object} Express应用实例
 */
function createApp() {
    const app = express();
    
    // 中间件配置
    app.use(cors());
    app.use(express.json({ limit: '10mb' }));
    app.use(express.urlencoded({ extended: true }));
    
    // 请求日志中间件
    app.use((req, res, next) => {
        logger.info(`${req.method} ${req.path} - ${req.ip}`);
        next();
    });
    
    // 健康检查端点
    app.get('/health', (req, res) => {
        res.json({
            status: 'ok',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            version: process.env.npm_package_version || '1.0.0'
        });
    });
    
    // 错误处理中间件
    app.use((error, req, res, next) => {
        logger.error('请求处理错误:', error);
        
        res.status(error.status || 500).json({
            error: {
                message: error.message || '内部服务器错误',
                status: error.status || 500,
                timestamp: new Date().toISOString()
            }
        });
    });
    
    return app;
}

/**
 * 启动服务器
 */
function startServer() {
    try {
        logger.info('正在启动开发服务器...');
        
        // 创建应用
        const app = createApp();
        
        // 启动服务器
        const server = app.listen(CONFIG.PORT, CONFIG.HOST, () => {
            logger.success(`服务器已启动:`);
            logger.info(`- 地址: http://${CONFIG.HOST}:${CONFIG.PORT}`);
            logger.info(`- 环境: ${CONFIG.NODE_ENV}`);
            logger.info(`- 进程ID: ${process.pid}`);
        });
        
        // 设置优雅关闭
        setupGracefulShutdown(server);
        
    } catch (error) {
        logger.error('启动服务器失败:', error);
        process.exit(1);
    }
}
```

### 📋 主函数和错误处理
```javascript
/**
 * 显示帮助信息
 */
function showHelp() {
    console.log(`
用法: node ${path.basename(__filename)} [选项]

选项:
    -h, --help      显示此帮助信息
    -p, --port      指定端口号 (默认: 3001)
    -H, --host      指定主机地址 (默认: localhost)
    -v, --verbose   详细输出模式

示例:
    node ${path.basename(__filename)}                    # 使用默认配置
    node ${path.basename(__filename)} --port 8080       # 指定端口
    node ${path.basename(__filename)} --verbose         # 详细输出

环境变量:
    PORT            服务器端口
    HOST            服务器主机
    NODE_ENV        运行环境
    LOG_LEVEL       日志级别
`);
}

/**
 * 解析命令行参数
 * @param {Array} args - 命令行参数
 */
function parseArguments(args) {
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        
        switch (arg) {
            case '-h':
            case '--help':
                showHelp();
                process.exit(0);
                break;
                
            case '-p':
            case '--port':
                if (i + 1 < args.length) {
                    CONFIG.PORT = parseInt(args[++i], 10);
                    if (isNaN(CONFIG.PORT)) {
                        logger.error('端口号必须是数字');
                        process.exit(1);
                    }
                } else {
                    logger.error('--port 选项需要一个值');
                    process.exit(1);
                }
                break;
                
            case '-H':
            case '--host':
                if (i + 1 < args.length) {
                    CONFIG.HOST = args[++i];
                } else {
                    logger.error('--host 选项需要一个值');
                    process.exit(1);
                }
                break;
                
            case '-v':
            case '--verbose':
                CONFIG.LOG_LEVEL = 'debug';
                break;
                
            default:
                logger.error(`未知参数: ${arg}`);
                showHelp();
                process.exit(1);
        }
    }
}

/**
 * 全局错误处理
 */
process.on('uncaughtException', (error) => {
    logger.error('未捕获的异常:', error);
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('未处理的Promise拒绝:', reason);
    process.exit(1);
});

/**
 * 主函数
 */
function main() {
    try {
        // 解析命令行参数
        parseArguments(process.argv.slice(2));
        
        // 启动服务器
        startServer();
        
    } catch (error) {
        logger.error('脚本执行失败:', error);
        process.exit(1);
    }
}

// 执行主函数
if (require.main === module) {
    main();
}

module.exports = {
    createApp,
    startServer,
    CONFIG
};
```

## 脚本质量规范

### 📋 代码质量检查清单
- [ ] 脚本头部信息完整
- [ ] 设置了严格模式 (`set -euo pipefail`)
- [ ] 包含错误处理和清理函数
- [ ] 日志输出格式统一
- [ ] 参数验证和帮助信息
- [ ] 适当的注释和文档
- [ ] 可执行权限设置正确
- [ ] 路径处理安全可靠

### 🔍 安全规范
```bash
# 1. 避免使用eval和动态执行
# ❌ 错误示例
eval "rm -rf $user_input"

# ✅ 正确示例
if [[ "$user_input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    rm -rf "/safe/path/${user_input}"
fi

# 2. 引用变量防止注入
# ❌ 错误示例
rm -rf $directory

# ✅ 正确示例
rm -rf "${directory}"

# 3. 验证输入参数
validate_input() {
    local input="$1"
    if [[ ! "$input" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        log_error "输入包含非法字符: $input"
    fi
}
```

### 🧪 测试规范
```bash
# 脚本测试函数示例
test_function() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        log_success "测试通过: $test_name"
        return 0
    else
        log_error "测试失败: $test_name (期望: $expected, 实际: $actual)"
        return 1
    fi
}

# 运行测试
run_tests() {
    log_info "开始运行测试..."
    
    local test_count=0
    local pass_count=0
    
    # 测试示例
    ((test_count++))
    if test_function "基本功能测试" "expected_value" "$(some_function)"; then
        ((pass_count++))
    fi
    
    log_info "测试结果: $pass_count/$test_count 通过"
    
    if [[ $pass_count -eq $test_count ]]; then
        log_success "所有测试通过"
        return 0
    else
        log_error "部分测试失败"
        return 1
    fi
}
```

## 脚本维护规范

### 📅 版本控制
```bash
# 脚本版本信息
readonly SCRIPT_VERSION="1.2.0"
readonly SCRIPT_DATE="2025-10-11"

# 版本历史记录
show_version() {
    cat << EOF
脚本版本: $SCRIPT_VERSION
更新日期: $SCRIPT_DATE

版本历史:
  1.2.0 (2025-10-11) - 添加错误重试机制
  1.1.0 (2025-10-01) - 增加详细日志输出
  1.0.0 (2025-09-15) - 初始版本
EOF
}
```

### 📊 性能监控
```bash
# 性能监控函数
monitor_performance() {
    local start_time=$(date +%s)
    local start_memory=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2}')
    
    # 执行主要逻辑
    "$@"
    
    local end_time=$(date +%s)
    local end_memory=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2}')
    local duration=$((end_time - start_time))
    
    log_info "性能统计:"
    log_info "- 执行时间: ${duration}秒"
    log_info "- 内存使用: ${start_memory}% -> ${end_memory}%"
}
```

### 🔧 自动化工具集成
```json
{
  "scripts": {
    "scripts:lint": "shellcheck scripts/**/*.sh",
    "scripts:test": "bats scripts/tests/*.bats",
    "scripts:format": "shfmt -w scripts/**/*.sh",
    "scripts:check": "npm run scripts:lint && npm run scripts:test"
  }
}
```

---

**制定日期**: 2025年10月11日  
**适用范围**: 所有项目脚本  
**维护责任**: 项目团队  
**下次审核**: 2025年11月11日