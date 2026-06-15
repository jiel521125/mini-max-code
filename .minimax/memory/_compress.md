# 递次压缩迁移规则

> **位置**：`./.minimax/memory\_compress.md`
> **目的**：当 memory.json / fix.json 超限时，定义如何递次压缩到 `_archive/`

## 核心原则

**不丢任何记录**——超限的记录迁移到 `_archive/` 永久保存，按"层"组织。

## 目录结构

```
memory/
├── agents/
│   └── <agent-id>/
│       ├── memory.json        当前活跃层
│       └── fix.json
└── _archive/
    ├── memory/
    │   └── <agent-id>/
    │       ├── layer-1-2026-Q2.json   100 条/层
    │       ├── layer-2-2026-Q1.json
    │       └── layer-3-2025-Q4.json
    └── fix/
        └── <agent-id>/
            ├── layer-1-2026-Q2.json   200 条/层
            └── ...
```

## 层命名规范

- **格式**：`layer-<N>-<YYYY>-<Q[1-4]>.json`
- **N**：层号（1, 2, 3, ...），越大越旧
- **YYYY-Qx**：层覆盖的季度（如 2026-Q2）

## 压缩触发条件

| 文件 | 上限 | 触发 |
|------|------|------|
| `agents/<id>/memory.json` | 100 条 | `current_count >= 100` 时，新写入前迁移最早 1 条 |
| `agents/<id>/fix.json` | 200 条 | `current_count >= 200` 时，新写入前迁移最早 1 条 |

## 压缩算法（memory.json）

```
[新 memory 写入触发]
    ↓
1. 读 agents/<id>/memory.json
    ↓
2. 若 current_count < 100：
   直接追加，写回
    ↓
3. 否则：
   a. 取 records[0]（最早一条）
   b. 删除 records[0]
   c. current_count -= 1
   d. 找到 _archive/memory/<id>/ 的最新 layer 文件
      - 若不存在：创建 layer-1-<当前季度>.json
      - 若存在但 >= 100 条：创建 layer-<N+1>-<当前季度>.json
      - 若存在且 < 100 条：追加到现有文件
   e. 追加原 records[0] 到对应 layer
   f. 追加新 record 到 records
   g. current_count += 1
   h. 更新 last_updated
   i. 同时写回 memory.json 和 layer 文件
```

## 压缩算法（fix.json）

同上，区别是上限 200 条/层。

## 层的容量

| 类型 | 单层容量 | 总上限 |
|------|---------|--------|
| memory | 100 条/层 | 无限（按季度） |
| fix | 200 条/层 | 无限（按季度） |

## 季度归并规则

- 一个 layer 最多装 100 条（memory）或 200 条（fix）
- 当 layer 装满且**仍在同一季度**时，创建下一层（layer-N+1）
- 跨季度时，**重置 layer 编号**（layer-1-<新季度>.json）

示例：
```
2026-Q2 的 memory 累积到 250 条
  → layer-1-2026-Q2.json (100 条)
  → layer-2-2026-Q2.json (100 条)
  → layer-3-2026-Q2.json (50 条 + 后面的)

2026-Q3 开始
  → layer-1-2026-Q3.json (0 条起步)
```

## 写 layer 文件的格式

```json
{
  "agent_id": "code-reviewer-v1",
  "schema_version": "1.0.0",
  "layer": 1,
  "quarter": "2026-Q2",
  "created_at": "2026-04-01T00:00:00+08:00",
  "last_updated": "2026-06-15T21:30:00+08:00",
  "record_count": 100,
  "records": [ ... 100 条 ... ]
}
```

## 召回（不是必需的，但支持）

如果子 Agent 需要查更早的历史（如某条 2 个季度前的会话）：

```
1. 读 _archive/memory/<id>/ 目录
2. 按 layer 编号倒序遍历
3. 找匹配的 record
```

**注意**：默认唤醒协议只读当前 memory.json，不主动查 archive（避免上下文爆炸）。

## 自动化建议

子 Agent 可以用一个工具函数封装压缩逻辑：

```python
def append_memory(agent_id, record):
    memory_file = f"memory/agents/{agent_id}/memory.json"
    data = read_json(memory_file)
    
    if data["current_count"] >= 100:
        # 迁移最早一条
        oldest = data["records"].pop(0)
        data["current_count"] -= 1
        archive_oldest(agent_id, "memory", oldest)
    
    # 追加新记录
    data["records"].append(record)
    data["current_count"] += 1
    data["last_updated"] = now_iso()
    
    write_json(memory_file, data)
```

## 与容量硬限的关系

- **写入侧**（当前 memory.json / fix.json）：硬限 ≤ 100/200
- **归档侧**（_archive/）：无硬限，按季度递次累积
- **总效果**：活跃层快速访问，归档层永久保留不丢失
