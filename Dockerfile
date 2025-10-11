# 前端应用多阶段构建 Dockerfile
# 基于设计文档的优化配置

# ================================
# 构建阶段 - 编译前端应用
# ================================
FROM node:18-alpine AS builder

# 设置构建参数
ARG BUILD_DATE
ARG VERSION=latest
ARG GIT_COMMIT=unknown
ARG GIT_BRANCH=unknown
ARG GIT_TAG=
ARG NODE_ENV=production

# 添加OCI标准标签信息
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/your-username/guessing-pen" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="旮旯画师前端应用" \
      org.opencontainers.image.description="基于React + TypeScript的AI艺术鉴别游戏前端应用" \
      org.opencontainers.image.vendor="Guessing Pen Team" \
      org.opencontainers.image.licenses="MIT" \
      maintainer="Guessing Pen Team" \
      version="${VERSION}" \
      git.commit="${GIT_COMMIT}" \
      git.branch="${GIT_BRANCH}" \
      git.tag="${GIT_TAG}"

# 设置工作目录
WORKDIR /app

# 优化Alpine镜像源（提高下载速度）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装构建依赖
RUN apk add --no-cache \
    git \
    curl \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

# 复制package文件（利用Docker缓存层）
COPY package*.json ./

# 配置npm（使用国内镜像源）
RUN npm config set registry https://registry.npmmirror.com \
    && npm config set disturl https://npmmirror.com/dist \
    && npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass

# 安装依赖（包括开发依赖用于构建）
RUN npm ci --frozen-lockfile --no-audit --no-fund

# 复制源代码
COPY . .

# 设置构建环境变量
ENV NODE_ENV=production
ENV VITE_APP_VERSION=${VERSION}
ENV VITE_BUILD_DATE=${BUILD_DATE}

# 构建应用
RUN npm run build

# 验证构建结果
RUN ls -la dist/ && \
    test -f dist/index.html && \
    echo "✅ 前端构建成功"

# ================================
# 生产阶段 - Nginx服务器
# ================================
FROM nginx:1.25-alpine AS production

# 设置构建参数
ARG BUILD_DATE
ARG VERSION=latest
ARG GIT_COMMIT=unknown
ARG GIT_BRANCH=unknown
ARG GIT_TAG=

# 添加OCI标准标签信息
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/your-username/guessing-pen" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="旮旯画师前端生产镜像" \
      org.opencontainers.image.description="基于Nginx的旮旯画师前端生产环境镜像" \
      org.opencontainers.image.vendor="Guessing Pen Team" \
      org.opencontainers.image.licenses="MIT" \
      maintainer="Guessing Pen Team" \
      version="${VERSION}" \
      git.commit="${GIT_COMMIT}" \
      git.branch="${GIT_BRANCH}" \
      git.tag="${GIT_TAG}"

# 优化Alpine镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装运行时依赖
RUN apk add --no-cache \
    curl \
    tzdata \
    && rm -rf /var/cache/apk/*

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建必要的目录和用户
RUN mkdir -p /var/log/nginx /var/cache/nginx /usr/share/nginx/html \
    && chown -R nginx:nginx /var/log/nginx /var/cache/nginx /usr/share/nginx/html

# 复制Nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 复制构建产物
COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html

# 复制静态资源（卡片图片等）
COPY --from=builder --chown=nginx:nginx /app/public/cards /usr/share/nginx/html/cards
COPY --from=builder --chown=nginx:nginx /app/public/fonts /usr/share/nginx/html/fonts

# 创建健康检查脚本
RUN echo '#!/bin/sh\ncurl -f http://localhost/health || exit 1' > /usr/local/bin/healthcheck.sh \
    && chmod +x /usr/local/bin/healthcheck.sh

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# 设置运行时环境变量
ENV NGINX_WORKER_PROCESSES=auto
ENV NGINX_WORKER_CONNECTIONS=1024

# 使用非root用户运行（安全最佳实践）
USER nginx

# 启动命令
CMD ["nginx", "-g", "daemon off;"]