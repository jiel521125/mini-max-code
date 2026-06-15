#!/usr/bin/env bash
# install.sh — 在新机器/新位置安装本项目
# 1. 校验前置（bash, mavis, jq）
# 2. 校验必读文件
# 3. 注册 hook 到 mavis
# 4. 输出安装报告

set -e

# 颜色（无颜色也行）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 路径（项目根 = install.sh 所在目录的上两级）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
PATHS_CONFIG="$PROJECT_ROOT/config/paths.json"
PLATFORM_CONFIG="$PROJECT_ROOT/config/platform.json"
HOOK_FILE="$PROJECT_ROOT/hooks/project-bootstrap-check.md"

# ---------- 1. 前置校验 ----------
echo -e "${YELLOW}==> Step 1: 前置校验${NC}"

if ! command -v mavis &> /dev/null; then
  echo -e "${RED}✗ mavis CLI 未找到${NC}"
  echo "  请先安装 mavis: https://mavis.example.com/install"
  exit 1
fi
echo "  ✓ mavis found: $(mavis --version 2>&1 | head -1)"

if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}! jq 未找到，将使用 grep 替代（功能受限）${NC}"
  HAS_JQ=false
else
  echo "  ✓ jq found: $(jq --version)"
  HAS_JQ=true
fi

# ---------- 2. 必读文件校验 ----------
echo -e "${YELLOW}==> Step 2: 必读文件校验${NC}"

MISSING=()
if [ -f "$PATHS_CONFIG" ] && [ "$HAS_JQ" = true ]; then
  while IFS= read -r f; do
    full="$PROJECT_ROOT/${f#./}"
    if [ ! -f "$full" ]; then
      MISSING+=("$f")
    fi
  done < <(jq -r '.required_files_globs[]' "$PATHS_CONFIG")
else
  # fallback：硬编码最小清单
  for f in README.md project.json agents/README.md agents/_schema.md agents/registry.json workflows/README.md workflows/_intent-router.md workflows/_template.md workflows/INDEX.md rules/workflow-decisions.md config/paths.json config/platform.json; do
    if [ ! -f "$PROJECT_ROOT/$f" ]; then
      MISSING+=("$f")
    fi
  done
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "${RED}✗ 必读文件缺失：${NC}"
  for f in "${MISSING[@]}"; do
    echo "    - $f"
  done
  echo ""
  echo "可能原因：项目不完整，或 git clone 漏文件。"
  exit 2
fi
echo "  ✓ 13 个必读文件全在"

# ---------- 3. 注册 hook ----------
echo -e "${YELLOW}==> Step 3: 注册 hook${NC}"

if [ ! -f "$HOOK_FILE" ]; then
  echo -e "${RED}✗ Hook 文件不存在: $HOOK_FILE${NC}"
  exit 3
fi

# 先检查是否已注册
if mavis hook list 2>/dev/null | grep -q "mavis:project-bootstrap-check"; then
  echo "  ! hook 已存在，先删除旧的"
  mavis hook delete mavis:project-bootstrap-check 2>/dev/null || true
fi

# 创建 hook
if mavis hook create project-bootstrap-check \
  --event SessionStart \
  --type script \
  --agent mavis \
  --priority 5 \
  --timeout 10000 \
  --file "$HOOK_FILE" &> /tmp/install-hook.log; then
  echo "  ✓ hook 注册成功: mavis:project-bootstrap-check"
else
  echo -e "${RED}✗ hook 注册失败${NC}"
  cat /tmp/install-hook.log
  exit 4
fi

# ---------- 4. 安装报告 ----------
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  安装完成 ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "项目根: $PROJECT_ROOT"
echo "Mavis agent: mavis"
echo "Hook: mavis:project-bootstrap-check (SessionStart)"
echo ""
echo "下一步："
echo "  1. 启动 mavis session，hook 会自动校验必读文件"
echo "  2. 应急跳过：MAVIS_PROJECT_BOOTSTRAP_SKIP=1 mavis ..."
echo ""
echo "验证："
echo "  mavis hook list | grep project-bootstrap-check"
echo ""
