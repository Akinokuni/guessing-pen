# 阿里云ACR镜像仓库管理脚本

本目录包含了管理阿里云容器镜像服务(ACR)的完整脚本集合，支持镜像仓库设置、构建推送、版本管理和信息查看。

## 📋 脚本列表

### 核心脚本
- **`acr-setup.sh`** - ACR仓库初始化设置
- **`acr-push.sh`** - 镜像构建和推送
- **`version-tag.sh`** - 语义化版本标签管理
- **`image-info.sh`** - 镜像信息查看工具

### 配置文件
- **`acr-config.json`** - ACR配置规范
- **`set-permissions.bat`** - Windows权限设置脚本

## 🚀 快速开始

### 1. 环境准备

#### 必需工具
```bash
# 检查必需工具
docker --version
git --version
aliyun version  # 阿里云CLI (仅setup脚本需要)
```

#### 环境变量设置
```bash
# 设置ACR凭证
export ACR_REGISTRY="registry.cn-hangzhou.aliyuncs.com"
export ACR_NAMESPACE="guessing-pen"
export ACR_USERNAME="qgl233"
export ACR_PASSWORD="20138990398QGL@gmailcom"
```

### 2. 初始化ACR仓库

```bash
# 设置脚本权限 (Linux/macOS)
chmod +x scripts/deployment/*.sh

# Windows环境
scripts/deployment/set-permissions.bat

# 初始化ACR仓库和命名空间
bash scripts/deployment/acr-setup.sh

# 试运行模式（仅查看配置）
bash scripts/deployment/acr-setup.sh --dry-run
```

### 3. 构建和推送镜像

```bash
# 构建并推送所有镜像
bash scripts/deployment/acr-push.sh

# 只构建前端镜像
bash scripts/deployment/acr-push.sh --target frontend

# 只构建API镜像
bash scripts/deployment/acr-push.sh --target api
```

### 4. 版本标签管理

```bash
# 创建patch版本 (如 v1.0.0 -> v1.0.1)
bash scripts/deployment/version-tag.sh patch

# 创建minor版本 (如 v1.0.0 -> v1.1.0)
bash scripts/deployment/version-tag.sh minor

# 创建major版本 (如 v1.0.0 -> v2.0.0)
bash scripts/deployment/version-tag.sh major

# 自动推送标签
bash scripts/deployment/version-tag.sh patch --auto-push
```

### 5. 查看镜像信息

```bash
# 查看镜像完整信息
bash scripts/deployment/image-info.sh nginx:latest

# 查看ACR镜像信息
bash scripts/deployment/image-info.sh registry.cn-hangzhou.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest

# 比较两个镜像
bash scripts/deployment/image-info.sh image1:tag1 compare image2:tag2
```

## 📖 详细使用说明

### ACR仓库设置 (acr-setup.sh)

#### 功能特性
- 自动创建ACR命名空间
- 创建前端和API镜像仓库
- 配置Docker登录凭证
- 显示配置信息

#### 使用方法
```bash
# 基本用法
bash scripts/deployment/acr-setup.sh

# 自定义配置
bash scripts/deployment/acr-setup.sh -n my-namespace -r registry.cn-beijing.aliyuncs.com

# 查看帮助
bash scripts/deployment/acr-setup.sh --help
```

#### 环境变量
- `ACR_REGISTRY` - ACR注册表地址
- `ACR_NAMESPACE` - ACR命名空间
- `ACR_USERNAME` - ACR用户名
- `ACR_PASSWORD` - ACR密码

### 镜像推送 (acr-push.sh)

#### 功能特性
- 多阶段Docker构建
- 自动生成镜像标签
- 添加构建元数据
- 推送重试机制
- 构建结果摘要

#### 标签策略
- `{branch}-{commit}` - 基于分支和提交的标签
- `latest` - 主分支最新版本
- `v{version}` - 语义化版本标签
- `{timestamp}` - 时间戳标签

#### 使用方法
```bash
# 构建所有镜像
bash scripts/deployment/acr-push.sh

# 指定构建目标
bash scripts/deployment/acr-push.sh --target frontend
bash scripts/deployment/acr-push.sh --target api

# 自定义配置
ACR_NAMESPACE=my-namespace bash scripts/deployment/acr-push.sh
```

### 版本管理 (version-tag.sh)

#### 功能特性
- 语义化版本管理
- 自动生成变更日志
- Git标签创建和推送
- Docker标签策略生成
- 版本信息展示

#### 版本类型
- `major` - 主版本号 +1 (破坏性更改)
- `minor` - 次版本号 +1 (新功能)
- `patch` - 修订版本号 +1 (bug修复)

#### 使用方法
```bash
# 创建版本标签
bash scripts/deployment/version-tag.sh patch
bash scripts/deployment/version-tag.sh minor
bash scripts/deployment/version-tag.sh major

# 自动推送
bash scripts/deployment/version-tag.sh patch --auto-push

# 查看帮助
bash scripts/deployment/version-tag.sh --help
```

### 镜像信息查看 (image-info.sh)

#### 功能特性
- 镜像基本信息展示
- 构建元数据解析
- 安全信息检查
- 镜像层分析
- 镜像对比功能

#### 使用方法
```bash
# 查看完整信息
bash scripts/deployment/image-info.sh nginx:latest

# 查看特定信息
bash scripts/deployment/image-info.sh nginx:latest basic
bash scripts/deployment/image-info.sh nginx:latest build
bash scripts/deployment/image-info.sh nginx:latest labels

# 比较镜像
bash scripts/deployment/image-info.sh nginx:latest compare nginx:1.25
```

## 🔧 配置说明

### ACR配置 (acr-config.json)

配置文件包含以下部分：

#### 注册表配置
```json
{
  "registry": {
    "url": "registry.cn-hangzhou.aliyuncs.com",
    "region": "cn-hangzhou",
    "namespace": "guessing-pen"
  }
}
```

#### 仓库配置
```json
{
  "repositories": [
    {
      "name": "guessing-pen-frontend",
      "description": "前端应用镜像",
      "dockerfile": "Dockerfile",
      "context": "."
    }
  ]
}
```

#### 构建配置
```json
{
  "build": {
    "args": {
      "BUILD_DATE": "构建日期",
      "VERSION": "版本号",
      "GIT_COMMIT": "Git提交哈希"
    }
  }
}
```

### 镜像标签规范

#### OCI标准标签
- `org.opencontainers.image.created` - 创建时间
- `org.opencontainers.image.source` - 源代码地址
- `org.opencontainers.image.version` - 版本号
- `org.opencontainers.image.revision` - Git提交哈希
- `org.opencontainers.image.title` - 镜像标题
- `org.opencontainers.image.description` - 镜像描述

#### 自定义标签
- `git.commit` - Git提交哈希
- `git.branch` - Git分支名
- `git.tag` - Git标签名
- `maintainer` - 维护者信息

## 🔒 安全最佳实践

### 凭证管理
- 使用环境变量存储敏感信息
- 在CI/CD中使用Secrets管理
- 定期轮换访问密钥
- 限制ACR访问权限

### 镜像安全
- 使用官方基础镜像
- 定期更新基础镜像
- 扫描镜像漏洞
- 使用非root用户运行

### 网络安全
- 配置VPC网络访问
- 使用私有镜像仓库
- 启用访问日志记录
- 配置IP白名单

## 🚨 故障排查

### 常见问题

#### 1. Docker登录失败
```bash
# 检查凭证
echo $ACR_USERNAME
echo $ACR_PASSWORD

# 手动登录测试
docker login registry.cn-hangzhou.aliyuncs.com -u $ACR_USERNAME
```

#### 2. 镜像推送失败
```bash
# 检查网络连接
ping registry.cn-hangzhou.aliyuncs.com

# 检查镜像大小
docker images | grep guessing-pen

# 查看详细错误
docker push --debug registry.cn-hangzhou.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest
```

#### 3. 版本标签冲突
```bash
# 查看现有标签
git tag -l

# 删除错误标签
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

#### 4. 构建失败
```bash
# 检查Dockerfile语法
docker build --no-cache -f Dockerfile .

# 查看构建日志
docker build --progress=plain -f Dockerfile .
```

### 日志查看
```bash
# 查看Docker日志
docker logs <container_id>

# 查看系统日志
journalctl -u docker

# 查看构建历史
docker image history <image_name>
```

## 📚 参考资料

### 官方文档
- [阿里云容器镜像服务](https://help.aliyun.com/product/60716.html)
- [Docker官方文档](https://docs.docker.com/)
- [语义化版本规范](https://semver.org/lang/zh-CN/)
- [OCI镜像规范](https://github.com/opencontainers/image-spec)

### 最佳实践
- [Docker镜像构建最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [容器安全最佳实践](https://kubernetes.io/docs/concepts/security/)
- [CI/CD最佳实践](https://docs.github.com/en/actions/learn-github-actions/essential-features-of-github-actions)

---

**维护者**: Kiro AI Assistant  
**创建日期**: 2025年10月11日  
**版本**: 1.0.0  
**更新日期**: 2025年10月11日