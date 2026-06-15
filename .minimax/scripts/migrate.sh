#!/usr/bin/env bash
# migrate.sh — 一站式迁移到新机器
# 用法：
#   在新机器上跑：  ./scripts/migrate.sh --from /path/to/old/Agent --to /path/to/new/Agent
#   或交互式：      ./scripts/migrate.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 参数解析
FROM_DIR=""
TO_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --from) FROM_DIR="$2"; shift 2 ;;
    --to)   TO_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "用法："
      echo "  $0 --from <源目录> --to <目标目录>"
      echo "  $0   # 交互式"
      exit 0
      ;;
    *) echo -e "${RED}未知参数: $1${NC}"; exit 1 ;;
  esac
done

# 交互式补全
if [ -z "$FROM_DIR" ]; then
  read -p "源项目目录 (回车=当前目录): " FROM_DIR
  FROM_DIR="${FROM_DIR:-$PROJECT_ROOT}"
fi

if [ -z "$TO_DIR" ]; then
  read -p "目标项目目录: " TO_DIR
  if [ -z "$TO_DIR" ]; then
    echo -e "${RED}目标目录不能为空${NC}"
    exit 1
  fi
fi

# 转换为绝对路径
FROM_DIR="$( cd "$FROM_DIR" && pwd )"
TO_DIR="$( cd "$TO_DIR" && pwd )"

echo -e "${YELLOW}==> 迁移计划${NC}"
echo "  源: $FROM_DIR"
echo "  目标: $TO_DIR"
read -p "确认？(y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "已取消"
  exit 0
fi

# ---------- 1. 复制文件 ----------
echo -e "${YELLOW}==> Step 1: 复制文件${NC}"
mkdir -p "$TO_DIR"
# 排除临时文件和 git 目录
rsync -av --exclude='.git' --exclude='*.tmp' --exclude='*.log' --exclude='__pycache__' \
  "$FROM_DIR/" "$TO_DIR/" 2>/dev/null || cp -r "$FROM_DIR"/* "$TO_DIR/"
echo -e "${GREEN}  ✓ 文件已复制到 $TO_DIR${NC}"

# ---------- 2. 在新位置跑 install ----------
echo -e "${YELLOW}==> Step 2: 在新位置安装${NC}"
cd "$TO_DIR"
chmod +x scripts/*.sh 2>/dev/null || true
./scripts/install.sh

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  迁移完成 ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "原机器: 跑 ./scripts/uninstall.sh 清理旧 hook"
echo "新机器: 项目已在 $TO_DIR 运行"
