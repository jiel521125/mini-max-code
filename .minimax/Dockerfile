# 基于官方 mavis 镜像（待 mavis 发布 Docker 镜像后改）
# 当前用通用 Node 镜像作为占位
FROM node:20-alpine AS base

# 安装依赖
RUN apk add --no-cache bash jq git curl

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . /app/

# 设置脚本可执行
RUN chmod +x /app/scripts/*.sh

# 入口点
ENTRYPOINT ["/app/scripts/install.sh"]
CMD ["--help"]
