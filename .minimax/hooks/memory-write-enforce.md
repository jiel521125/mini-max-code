---
hookEvent: SessionEnd
type: script
priority: 5
timeout: 15000
---

```bash
# Mavis 项目记忆写入强校验（SessionEnd）
# 校验本次 session 涉及的子 Agent 是否都已写入 memory
# 应急跳过：MAVIS_MEMORY_ENFORCE_SKIP=1

# 应急逃生
if [ -n "$MAVIS_MEMORY_ENFORCE_SKIP" ]; then
  echo '{}'
  exit 0
fi

# 读取 hook payload
PAYLOAD=$(cat)
AGENT_NAME=$(echo "$PAYLOAD" | grep -o '"agentName":"[^"]*"' | head -1 | sed 's/.*:"\(.*\)"/\1/')
SESSION_ID=$(echo "$PAYLOAD" | grep -o '"sessionId":"[^"]*"' | head -1 | sed 's/.*:"\(.*\)"/\1/')
REASON=$(echo "$PAYLOAD" | grep -o '"reason":"[^"]*"' | head -1 | sed 's/.*:"\(.*\)"/\1/')

# 只对 mavis 主 agent 生效
if [ "$AGENT_NAME" != "mavis" ]; then
  echo '{}'
  exit 0
fi

# 定位 workspace
WORKSPACE_DIR=$(echo "$PAYLOAD" | grep -o '"workspaceDir":"[^"]*"' | head -1 | sed 's/.*:"\(.*\)"/\1/')
if [ -z "$WORKSPACE_DIR" ] || [ ! -d "$WORKSPACE_DIR" ]; then
  echo '{}'
  exit 0
fi

# 检查 memory/ 目录
MEMORY_DIR="$WORKSPACE_DIR/.minimax/memory"
if [ ! -d "$MEMORY_DIR" ]; then
  echo '{}'
  exit 0
fi

# 统计本 session 各子 Agent 的 memory.json 修改时间
# 简化版：只警告，不 abort
WARNINGS=()
for agent_dir in "$MEMORY_DIR/agents"/*/; do
  if [ ! -d "$agent_dir" ]; then continue; fi
  agent_id=$(basename "$agent_dir")
  mem_file="$agent_dir/memory.json"
  if [ -f "$mem_file" ]; then
    last_mod=$(stat -c %Y "$mem_file" 2>/dev/null || stat -f %m "$mem_file" 2>/dev/null)
    # 如果 memory.json 在 session 期间被修改过，认为已写
    # 否则警告
    if [ -n "$last_mod" ] && [ "$last_mod" -lt "$(date +%s -d '1 hour ago' 2>/dev/null || echo 0)" ]; then
      WARNINGS+=("$agent_id 的 memory.json 已超过 1 小时未更新")
    fi
  else
    WARNINGS+=("$agent_id 的 memory.json 不存在")
  fi
done

# 输出（不 abort，只警告 + 注入 metadata）
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [ ${#WARNINGS[@]} -gt 0 ]; then
  WARNING_STR="memory 写入提醒（不阻塞）："
  for w in "${WARNINGS[@]}"; do
    WARNING_STR="$WARNING_STR | $w"
  done
  WARNING_STR="$WARNING_STR | 应急跳过：MAVIS_MEMORY_ENFORCE_SKIP=1"
  
  ESCAPED=$(printf '%s' "$WARNING_STR" | sed 's/\\/\\\\/g; s/"/\\"/g')
  cat <<EOF
{
  "metadata": {
    "memory_check_warnings": "$ESCAPED",
    "session_id": "$SESSION_ID",
    "checked_at": "$NOW"
  }
}
EOF
else
  cat <<EOF
{
  "metadata": {
    "memory_check_passed": true,
    "session_id": "$SESSION_ID",
    "checked_at": "$NOW"
  }
}
EOF
fi
```
