# GitHub Actions 环境配置示例
# 此文件展示了所需的环境变量和Secrets配置
# 请根据实际情况在GitHub仓库设置中配置相应的Secrets和Variables

# ================================
# GitHub Secrets 配置
# ================================
# 在 GitHub 仓库的 Settings > Secrets and variables > Actions > Secrets 中添加：

secrets:
  # 阿里云ACR配置
  ACR_USERNAME: "your-aliyun-account"           # 阿里云ACR用户名
  ACR_PASSWORD: "your-acr-password"             # 阿里云ACR密码
  
  # 生产环境服务器配置
  PROD_SERVER_HOST: "your-production-server-ip" # 生产服务器IP
  PROD_SERVER_USER: "your-ssh-username"         # SSH用户名
  PROD_SERVER_SSH_KEY: |                        # SSH私钥（多行）
    -----BEGIN OPENSSH PRIVATE KEY-----
    your-private-key-content-here
    -----END OPENSSH PRIVATE KEY-----
  PROD_SERVER_PORT: "22"                        # SSH端口（可选，默认22）
  
  # 预发布环境服务器配置（可选）
  STAGING_SERVER_HOST: "your-staging-server-ip"
  STAGING_SERVER_USER: "your-ssh-username"
  STAGING_SERVER_SSH_KEY: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    your-staging-private-key-content-here
    -----END OPENSSH PRIVATE KEY-----
  STAGING_SERVER_PORT: "22"
  
  # 通知配置（可选）
  WEBHOOK_URL: "https://oapi.dingtalk.com/robot/send?access_token=your-token"
  ALERT_WEBHOOK_URL: "https://oapi.dingtalk.com/robot/send?access_token=your-alert-token"

# ================================
# GitHub Variables 配置
# ================================
# 在 GitHub 仓库的 Settings > Secrets and variables > Actions > Variables 中添加：

variables:
  PRODUCTION_URL: "https://your-domain.com"      # 生产环境访问地址
  STAGING_URL: "https://staging.your-domain.com" # 预发布环境访问地址（可选）

# ================================
# 环境配置说明
# ================================

# 1. 阿里云ACR配置步骤：
#    - 登录阿里云控制台
#    - 进入容器镜像服务ACR
#    - 创建命名空间：guessing-pen
#    - 设置Registry登录密码
#    - 将用户名和密码配置到GitHub Secrets

# 2. 服务器SSH配置步骤：
#    - 生成SSH密钥对：ssh-keygen -t rsa -b 4096 -C "github-actions@your-domain.com"
#    - 将公钥添加到服务器：~/.ssh/authorized_keys
#    - 将私钥配置到GitHub Secrets
#    - 确保服务器已安装Docker和Docker Compose

# 3. 服务器目录结构：
#    /opt/guessing-pen/
#    ├── docker-compose.prod.yml
#    ├── .env
#    ├── logs/
#    └── backups/

# 4. 通知配置（可选）：
#    - 钉钉机器人：创建群机器人，获取Webhook地址
#    - 企业微信机器人：创建群机器人，获取Webhook地址
#    - Slack：创建Incoming Webhook

# ================================
# 工作流触发条件
# ================================

# 自动触发：
# - 推送到main分支：触发完整CI/CD流程
# - 创建PR：只执行代码检查和测试
# - 推送标签（v*.*.*）：触发版本发布

# 手动触发：
# - 手动部署：可指定版本和环境
# - 回滚操作：可回滚到指定版本
# - 系统维护：清理镜像、日志等
# - 健康检查：全面系统检查

# ================================
# 安全注意事项
# ================================

# 1. Secrets安全：
#    - 定期轮换SSH密钥和ACR密码
#    - 使用最小权限原则
#    - 不在日志中输出敏感信息

# 2. 服务器安全：
#    - 配置防火墙规则
#    - 使用SSH密钥认证
#    - 定期更新系统和Docker

# 3. 网络安全：
#    - 使用HTTPS
#    - 配置安全头
#    - 定期检查SSL证书

# ================================
# 故障排查
# ================================

# 1. 查看GitHub Actions日志：
#    - 在仓库的Actions页面查看工作流执行日志
#    - 每个步骤都有详细的输出信息

# 2. 查看服务器日志：
#    - 部署日志：/opt/guessing-pen/logs/
#    - 容器日志：docker-compose logs
#    - 系统日志：journalctl

# 3. 常见问题：
#    - ACR登录失败：检查用户名和密码
#    - SSH连接失败：检查密钥和网络
#    - 部署失败：检查容器状态和日志
#    - 健康检查失败：检查服务端口和响应