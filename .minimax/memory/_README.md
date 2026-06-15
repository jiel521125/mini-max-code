# 自定义记忆体 README

> **位置**：`./.minimax/memory\`
> **目的**：解决"多轮会话后漂移"问题
> **核心机制**：每轮结束前写 memory，唤醒时召唤 6 条重组

## 这是什么

一个**项目级、强制的对话记忆体系**。每个子 Agent 维护自己的 `memory.json`（会话摘要）和 `fix.json`（修复经验），容量受控，超限自动压缩。

## 核心机制

### 1. 写入时机（强制）

| 触发 | 写什么 | 写到哪里 |
|------|--------|---------|
| **每轮对话结束前** | 当前轮的 QA 摘要 | Agent 的 `memory.json` |
| **修复/Debug 完成且无错** | 修复经验 | Agent 的 `fix.json` |

**"每轮结束前"**的定义：
- 子 Agent 自己的对话明显结束（输出"已完成"+ 等待下一步）
- 主 agent 调用子 Agent 后收到返回结果时
- 一个子任务的工作流步骤完成时

### 2. 容量管理

| 文件 | 上限 | 超限动作 |
|------|------|---------|
| `memory.json` | 100 条 | 迁移最早 1 条到 `_archive/memory/<agent-id>/layer-N-*.json` |
| `fix.json` | 200 条 | 迁移最早 1 条到 `_archive/fix/<agent-id>/layer-N-*.json` |

### 3. 唤醒协议

子 Agent 唤醒时按 `_wakeup-protocol.md` 执行：
1. 读 `memory.json` 最新 3 条
2. 读 `fix.json` 最新 3 条
3. 读项目必读清单（已在前面的 MEMORY.md 维护）
4. 把 6 条记忆 + 项目约束重组
5. 开始对话

### 4. 强制机制

- **PostToolUse hook（提醒）**：每次子 Agent 工具调用后，提醒"该写 memory 了"
- **SessionEnd hook（强校验）**：session 结束时，检查本 session 是否有未写入的对话，无则 abort

## 写入流程

```
[子 Agent 完成一轮任务]
    ↓
1. 生成 memory_id：mem_<agent-id>_<4位序号>
    ↓
2. 读现有 memory.json
    ↓
3. 若 current_count >= 100：
   迁移最早 1 条到 _archive/memory/<agent-id>/layer-N-*.json
    ↓
4. 追加新 record 到 records 数组
    ↓
5. 更新 last_updated 和 current_count
    ↓
6. 写回 memory.json
```

## 修复经验写入流程

```
[子 Agent 完成 Debug/修复 且无错]
    ↓
1. 生成 fix_id：fix_<agent-id>_<3位序号>
    ↓
2. 提取：failure_reason / root_cause / fix_method / fix_effect / prevention
    ↓
3. 读现有 fix.json
    ↓
4. 若 current_count >= 200：
   迁移最早 1 条到 _archive/fix/<agent-id>/layer-N-*.json
    ↓
5. 追加 + 更新 + 写回
```

## 子 Agent 必须做的事

每个子 Agent 的 `prompt.md` 末尾**必须**包含以下自检：

```markdown
## 记忆维护（强制）

每轮任务完成前，你**必须**执行：
1. 生成 memory record（参考 memory/_schema.md）
2. 追加到 memory/agents/<your-id>/memory.json
3. 若超限，按 _compress.md 迁移最早一条

Debug/修复完成且无错时，**必须**追加 fix record 到 fix.json
```

## 主 agent 的责任

主 agent 不直接写子 Agent 的 memory（你 Q3b 决定子 Agent 自己管）。主 agent 的责任：

1. **编排** 子 Agent 时，**附带** `memory/agents/<sub-id>/memory.json` 路径，让子 Agent 知道写哪里
2. **监听** 子 Agent 的返回，若返回中包含 `memory_written: true` 标记，则信任
3. **会话结束时**触发 SessionEnd hook 校验

## 启动检查

主 agent 启动时（已被 SessionStart hook 强制）**必须**确认：
- `memory/_schema.md` 存在
- `memory/_README.md` 存在
- `memory/_wakeup-protocol.md` 存在
- `memory/_compress.md` 存在
- 每个 `agents/<id>/` 下都有 `memory.json` 和 `fix.json`（即使空）

## 与其他子系统的关系

- **项目必读清单**：memory 的 4 个机制文件已被加入 `config/paths.json` 和 MEMORY.md
- **hooks**：2 个新 hook 接管 memory 写入提醒和强校验
- **固化工作流**：每个固化工作流的步骤里都引用子 Agent，由子 Agent 自己维护 memory

## 应急与维护

| 场景 | 处理 |
|------|------|
| memory.json 损坏 | 从 `_archive/` 最近的 layer 恢复最新 100 条 |
| 子 Agent 忘记写 | SessionEnd hook 拦截，强制补写 |
| 想查看某 Agent 的全部历史 | 合并 memory.json + `_archive/` 的所有 layer |
| 跨机器迁移 | memory/ 整体随项目一起迁移（含 `_archive/`） |

## 设计原则

1. **子 Agent 自管**：避免主 agent 成为瓶颈
2. **每轮必写**：高频小颗粒，避免漏写
3. **容量硬限**：防止无限膨胀
4. **递次压缩**：保留全部历史，不丢弃
5. **唤醒仪式**：6 条记忆足够恢复上下文
