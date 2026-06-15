# 会话唤醒协议：6 条记忆重组

> **位置**：`./.minimax/memory\_wakeup-protocol.md`
> **目的**：子 Agent 被唤醒时，**必须**按此协议重组上下文
> **核心**：召唤最新 3+3 共 6 条记忆 + 项目必读清单

## 协议流程

```
[子 Agent 收到唤醒信号]
    ↓
1. 确认自己的 agent_id
    ↓
2. 读 memory/agents/<agent_id>/memory.json 最新 3 条
    （按 records 数组的尾部倒序取 3 条）
    ↓
3. 读 memory/agents/<agent_id>/fix.json 最新 3 条
    （按 records 数组的尾部倒序取 3 条）
    ↓
4. 读项目必读清单（从 MEMORY.md / config/paths.json 加载）
    ↓
5. 重组上下文（见下文）
    ↓
6. 开始对话
```

## 重组上下文的格式

```markdown
## 上下文重组（唤醒注入）

### Agent 身份
- ID: <agent_id>
- 角色: <agent_role>
- 唤醒时间: <ISO 8601>

### 最近 3 条会话摘要（来自 memory.json）
1. [<input_time>] <question>
   → <answer> 概要
   关键要点: <key_takeaways>
2. [<input_time>] <question>
   → <answer> 概要
3. [<input_time>] <question>
   → <answer> 概要

### 最近 3 条修复经验（来自 fix.json）
1. [<fix_time>] <failure_reason> 概要
   修复: <fix_method> 概要
   效果: <fix_effect> 概要
   预防: <prevention> 概要
2. [<fix_time>] <failure_reason> 概要
3. [<fix_time>] <failure_reason> 概要

### 项目必读清单（关键摘要）
- 固化工作流模板库: ./.minimax/workflows\
- 已注册子 Agent: <registry 摘要>
- 当前活跃固化工作流: <workflows/INDEX.md 摘要>
- 项目核心约定: <必读清单 5 条>

### 当前任务
<主 agent 分发的任务描述>
```

## 取最新 N 条的实现

```python
def get_recent_records(file_path, n=3):
    data = read_json(file_path)
    records = data.get("records", [])
    # records 是按时间追加的，尾部最新
    return records[-n:] if len(records) >= n else records
```

## 注入时机

- **子 Agent 启动时**：必须注入
- **跨多轮任务**：每轮开始前**不重新注入**（已经在上下文里），但主 agent 可显式要求"刷新上下文"
- **跨 session**：必须重新注入（新 session 是新上下文）

## 注入失败的处理

如果 `memory.json` 或 `fix.json` 缺失：

```
警告：<agent_id> 的 memory.json 不存在，使用空上下文启动
警告：<agent_id> 的 fix.json 不存在，使用空上下文启动
继续对话（不阻塞），但提醒主 agent 注意此 Agent 首次使用
```

## 6 条记忆够不够？

**设计依据**：
- 3 条 memory ≈ 最近 3 轮对话的关键 QA，覆盖"我最近在做什么、结果如何"
- 3 条 fix ≈ 最近 3 次修复经验，覆盖"我最近踩过什么坑、怎么避的"
- 共 6 条 ≈ 1500-3000 token，**在大多数 LLM 上下文窗口内可承受**

**如果不够**（极端情况）：
- 显式调用"加载更多"：主 agent 可指定 `load_recent_count: 10`
- 查 archive：按时间范围查 `_archive/`

## 唤醒 vs 每轮结束

| 时机 | 行为 | 读什么 |
|------|------|--------|
| 唤醒（session 开始） | 注入 6 条到上下文 | memory.json + fix.json 最新 3+3 |
| 每轮结束 | 追加 1 条到 memory.json | 当前轮 QA |
| 修复完成 | 追加 1 条到 fix.json | 修复经验 |
| 超限 | 迁移最早 1 条到 _archive | records[0] |

## 子 Agent 必读

子 Agent 的 `prompt.md` 末尾**必须**包含：

```markdown
## 唤醒协议（强制）

你被唤醒时，**必须**先执行：
1. 读 memory/agents/<your-id>/memory.json
2. 读 memory/agents/<your-id>/fix.json
3. 提取最新 3 条 memory + 最新 3 条 fix
4. 与项目必读清单重组上下文
5. 输出"上下文重组完成"标记
6. **然后**开始对话

如未执行此协议直接对话，视为越界。
```

## 测试用例（自检）

每个子 Agent 部署后应能通过以下自检：

- [ ] 唤醒时输出"上下文重组完成"
- [ ] 重组内容包含 3 条 memory + 3 条 fix
- [ ] 重组内容包含项目必读清单的关键条目
- [ ] 每轮结束前自动写 memory.json
- [ ] 修复完成后自动写 fix.json
- [ ] 超限自动迁移到 _archive/
