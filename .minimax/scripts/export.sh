#!/usr/bin/env bash
# export.sh — 打包项目（不含临时文件），方便分发/备份
# 用法：./scripts/export.sh [/path/to/output.zip]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
PROJECT_NAME=$(basename "$PROJECT_ROOT")
VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_ROOT/project.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')

# 默认输出路径
DEFAULT_OUTPUT="$PROJECT_ROOT/${PROJECT_NAME}-v${VERSION}.zip"
OUTPUT="${1:-$DEFAULT_OUTPUT}"

echo -e "${YELLOW}==> 打包项目${NC}"
echo "  源: $PROJECT_ROOT"
echo "  输出: $OUTPUT"

# 检测平台
IS_WINDOWS=false
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
  IS_WINDOWS=true
fi

# 打包（跨平台：zip 优先，PowerShell 兜底）
if command -v zip &> /dev/null; then
  cd "$PROJECT_ROOT"
  # 排除 .git / 临时文件 / 旧 zip
  zip -r "$OUTPUT" . \
    -x "*.git*" \
    -x "*.tmp" \
    -x "*.log" \
    -x "*.zip" \
    -x "__pycache__/*" \
    -x "node_modules/*" &> /dev/null
  echo -e "${GREEN}  ✓ zip 打包完成${NC}"
elif [ "$IS_WINDOWS" = true ] && command -v powershell &> /dev/null; then
  # Windows fallback：PowerShell Compress-Archive
  powershell -Command "Compress-Archive -Path '$PROJECT_ROOT\*' -DestinationPath '$OUTPUT' -Force" &> /dev/null
  echo -e "${GREEN}  ✓ PowerShell 打包完成${NC}"
else
  echo -e "${RED}  ✗ 找不到 zip 或 PowerShell${NC}"
  exit 1
fi

# 报告
SIZE=$(ls -lh "$OUTPUT" 2>/dev/null | awk '{print $5}')
echo ""
echo -e "${GREEN}打包完成${NC}"
echo "  文件: $OUTPUT"
echo "  大小: $SIZE"
echo ""
echo "在目标机器上："
echo "  unzip $OUTPUT -d /new/path/"
echo "  cd /new/path/Agent"
echo "  ./scripts/install.sh"
