# 多阶段构建 Dockerfile - 猜猜笔挑战

# 构建阶段
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 设置Alpine镜像源（解决网络问题）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装必要的系统依赖（添加超时和重试机制）
RUN apk add --no-cache --timeout=300 git curl

# 复制 package 文件
COPY package*.json ./

# 设置npm镜像源（加速下载）
RUN npm config set registry https://registry.npmmirror.com

# 安装依赖（包括开发依赖，因为需要构建）
RUN npm ci --frozen-lockfile --timeout=300000

# 复制源代码
COPY . .

# 构建应用（Docker专用构建命令）
RUN npm run build:docker

# 生产阶段
FROM nginx:alpine AS production

# 设置Alpine镜像源（解决网络问题）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装必要的工具（添加超时机制）
RUN apk add --no-cache --timeout=300 curl tzdata

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建必要的目录
RUN mkdir -p /var/log/nginx /var/cache/nginx

# 复制自定义 nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制卡片图片
COPY --from=builder /app/public/cards /usr/share/nginx/html/cards

# 设置正确的权限
RUN chown -R nginx:nginx /usr/share/nginx/html /var/log/nginx /var/cache/nginx

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]