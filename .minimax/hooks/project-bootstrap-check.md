---
hookEvent: SessionStart
type: script
priority: 5
timeout: 10000
---

```bash
# Mavis 项目启动硬约束（重构版：路径抽象 + 跨平台）
# 1. 应急逃生（最优先检查）
# 2. 读取 hook payload，定位 workspaceDir
# 3. 读取 config/paths.json 决定必读文件清单
# 4. 校验必读文件全在
# 5. 任一缺失 → abort；全部存在 → 注入 metadata

# 应急逃生
if [ -n "$MAVIS_PROJECT_BOOTSTRAP_SKIP" ]; then
  echo '{}'
  exit 0
fi

# 读取 hook 协议 payload（stdin）
PAYLOAD=$(cat)
AGENT_NAME=$(echo "$PAYLOAD" | grep -o '"agentName":"[^"]*"' | head -1 | sed 's/.*:"\(.*\)"/\1/')

# 只对 mavis agent 生效
if [ "$AGENT_NAME" != "mavis" ]; then
  echo '{}'
  exit 0
fi

# 定位 workspaceDir（hook payload 里有）
WORKSPACE_DIR=$(echo "$PAYLOAD" | grep -o '"workspaceDir":"[^"]*"' | head -1 | sed 's/.*:"\(.*\)"/\1/')

# 兜底：如果 workspaceDir 为空，尝试从环境变量取
if [ -z "$WORKSPACE_DIR" ]; then
  if [ -n "$MAVIS_WORKSPACE" ]; then
    WORKSPACE_DIR="$MAVIS_WORKSPACE"
  fi
fi

# 兜底 2：HOME + 推断
if [ -z "$WORKSPACE_DIR" ] && [ -d "$HOME/Agent" ]; then
  WORKSPACE_DIR="$HOME/Agent"
fi

# 仍然没找到 → abort
if [ -z "$WORKSPACE_DIR" ] || [ ! -d "$WORKSPACE_DIR" ]; then
  printf '{"_abort":{"reason":"workspaceDir 未指定或目录不存在（hook payload: %s）"}}\n' "$PAYLOAD" | head -c 200
  echo
  exit 0
fi

# 必读文件清单：优先读 paths.json，回退到硬编码最小集
PATHS_JSON="$WORKSPACE_DIR/.minimax/config/paths.json"
REQUIRED_FILES=()

if [ -f "$PATHS_JSON" ] && command -v jq >/dev/null 2>&1; then
  # 用 jq 解析
  while IFS= read -r f; do
    REQUIRED_FILES+=("$f")
  done < <(jq -r '.required_files_globs[]' "$PATHS_JSON" 2>/dev/null)
fi

# 兜底：硬编码最小集
if [ ${#REQUIRED_FILES[@]} -eq 0 ]; then
  REQUIRED_FILES=(
    "./.minimax/README.md"
    "./.minimax/project.json"
    "./.minimax/agents/README.md"
    "./.minimax/agents/_schema.md"
    "./.minimax/agents/registry.json"
    "./.minimax/workflows/README.md"
    "./.minimax/workflows/_intent-router.md"
    "./.minimax/workflows/_template.md"
    "./.minimax/workflows/INDEX.md"
    "./.minimax/rules/workflow-decisions.md"
    "./.minimax/config/paths.json"
    "./.minimax/config/platform.json"
    "./.minimax/scripts/install.sh"
  )
fi

# 校验
MISSING=()
for f in "${REQUIRED_FILES[@]}"; do
  # 处理 ./ 前缀
  rel="${f#./}"
  full="$WORKSPACE_DIR/$rel"
  if [ ! -f "$full" ]; then
    MISSING+=("$f")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  # 任一缺失 → abort
  REASON="项目必读文件缺失（mavis 项目硬约束），workspaceDir=$WORKSPACE_DIR："
  for f in "${MISSING[@]}"; do
    REASON="$REASON | $f"
  done
  REASON="$REASON || 应急跳过：MAVIS_PROJECT_BOOTSTRAP_SKIP=1"

  # JSON 转义
  ESCAPED=$(printf '%s' "$REASON" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"_abort":{"reason":"%s"}}\n' "$ESCAPED"
  exit 0
fi

# 全部存在 → 放行 + 注入 metadata
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat <<EOF
{
  "metadata": {
    "project_bootstrap": "E:\\TianShu\\Agent",
    "workspace_dir": "$WORKSPACE_DIR",
    "bootstrap_check_passed": true,
    "bootstrap_checked_at": "$NOW",
    "required_files_count": ${#REQUIRED_FILES[@]}
  }
}
EOF
```
