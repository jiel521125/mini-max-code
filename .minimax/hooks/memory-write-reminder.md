---
hookEvent: PostToolUse
type: prompt
priority: 40
matcher: "^(bash|edit|write|read)$"
timeout: 5000
---

子 Agent 提示（PostToolUse 提醒写入记忆）

你刚刚完成了一次工具调用：tool={{input.toolName}}

如果这是一轮对话的"完成"标志（输出结果、完成任务、给出结论），请**立即**检查：

1. 本轮对话是否已产生可摘要的 QA 结果？
   - 是 → 追加 1 条 record 到 `memory/agents/<your-agent-id>/memory.json`
   - 否 → 继续

2. 本轮是否完成了 Debug/修复且无错？
   - 是 → 追加 1 条 record 到 `memory/agents/<your-agent-id>/fix.json`
   - 否 → 继续

3. 当前 memory.json / fix.json 是否已超限（100/200）？
   - 是 → 按 `memory/_compress.md` 迁移最早一条到 `_archive/`

**写入规范**见 `memory/_schema.md`

**应急跳过**：`MAVIS_MEMORY_WRITE_SKIP=1` 可跳过本提醒（不推荐）

**注意**：这只是提醒，**不强制**。SessionEnd 时会有强校验 hook 兜底。
