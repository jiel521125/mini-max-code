# 自定义记忆体 Schema 规范 (v1.0.0)

> **位置**：`./.minimax/memory\`
> **职责**：定义 memory.json 和 fix.json 的字段规范
> **继承**：本规范在项目原 AGENTS.md 7.2 节基础上扩展
> **增强点**：增加 `tags`、`task_id`、`workflow_id`、`files_touched`、`outcome` 等新字段

## 目录结构

```
memory/
├── _schema.md             ← 本文件
├── _README.md             ← 写入流程、唤醒仪式、容量管理
├── _compress.md           ← 递次压缩迁移规则
├── _wakeup-protocol.md    ← 会话唤醒 6 条记忆重组规则
│
├── agents/                ← 按 Agent 分类
│   ├── mavis/
│   │   ├── memory.json    ≤100 条
│   │   └── fix.json       ≤200 条
│   ├── code-reviewer-v1/
│   │   ├── memory.json
│   │   └── fix.json
│   ├── api-designer-v1/
│   ├── test-generator-v1/
│   └── coder-v1/
│
├── tasks/                 ← 按任务分类（任务级，非 Agent 级）
│   └── <task-id>/
│       ├── memory.json
│       └── fix.json
│
└── _archive/              ← 压缩归档（递次记忆）
    ├── memory/
    │   ├── <agent-id>/
    │   │   ├── layer-1-2026-Q2.json   最近压缩层
    │   │   ├── layer-2-2026-Q1.json
    │   │   └── layer-3-2025-Q4.json
    │   └── ...
    └── fix/
        └── ...
```

## memory.json 字段规范

```json
{
  "agent_id": "code-reviewer-v1",
  "agent_role": "code-reviewer",
  "schema_version": "1.0.0",
  "created_at": "2026-06-15T21:26:00+08:00",
  "last_updated": "2026-06-15T21:26:00+08:00",
  "max_records": 100,
  "current_count": 0,
  "records": [
    {
      "memory_id": "mem_code-reviewer-v1_0042",
      "session_id": "ses_20260615_001",
      "task_id": "task_feature-develop-0001_20260615",
      "workflow_id": "feature-develop-0001",
      "question": "审查 src/api/users.py 的用户登录接口",
      "answer": "通过，9 维度均 OK，得分 92，主要亮点：命名规范、边界处理完善",
      "input_time": "2026-06-15T21:00:00+08:00",
      "output_time": "2026-06-15T21:05:00+08:00",
      "duration_seconds": 300,
      "context_version": "v1.0.0",
      "tags": ["api", "auth", "review-pass"],
      "files_touched": ["src/api/users.py"],
      "outcome": "pass",
      "score": 92,
      "key_takeaways": [
        "JWT 鉴权中间件提取得当",
        "边界条件（token 过期、签名错）覆盖完整"
      ]
    }
  ]
}
```

## fix.json 字段规范

```json
{
  "agent_id": "code-reviewer-v1",
  "schema_version": "1.0.0",
  "created_at": "2026-06-15T21:26:00+08:00",
  "last_updated": "2026-06-15T21:26:00+08:00",
  "max_records": 200,
  "current_count": 0,
  "records": [
    {
      "fix_id": "fix_code-reviewer-v1_001",
      "task_id": "task_bugfix-investigate-0001_20260615",
      "workflow_id": "bugfix-investigate-0001",
      "session_id": "ses_20260615_002",
      "failure_reason": "审查漏掉了 SQL 注入风险，原始 SQL 字符串拼接未识别",
      "root_cause": "9 维度审查的安全维度只检查了 OWASP Top 10 的高发项，未深入参数化查询",
      "fix_method": "在 check_dimensions.security 中加入 'sql-injection' 子项，强制所有 DB 调用走 ORM 或参数化查询",
      "fix_effect": "后续 5 次审查全部识别出 SQL 注入风险，0 误报",
      "fix_time": "2026-06-15T21:30:00+08:00",
      "duration_minutes": 45,
      "similar_cases": [],
      "fix_count": 1,
      "related_memory_ids": ["mem_code-reviewer-v1_0042"],
      "prevention": [
        "新增 review checklist: 数据库访问必须用 ORM/参数化",
        "CI 增加自动 SQL 注入扫描（sqlmap）"
      ],
      "tags": ["security", "sql-injection", "false-negative"]
    }
  ]
}
```

## 字段说明

### memory.json 字段

| 字段 | 必填 | 类型 | 说明 |
|------|------|------|------|
| `agent_id` | ✓ | string | Agent 唯一 ID（与目录名一致） |
| `agent_role` | ✓ | string | 角色简写 |
| `schema_version` | ✓ | string | 当前 schema 版本 |
| `created_at` | ✓ | ISO 8601 | 文件创建时间 |
| `last_updated` | ✓ | ISO 8601 | 最后更新时间 |
| `max_records` | ✓ | int | 上限（默认 100） |
| `current_count` | ✓ | int | 当前记录数 |
| `records` | ✓ | array | 记录数组 |
| `records[].memory_id` | ✓ | string | `mem_<agent-id>_<4位序号>` |
| `records[].session_id` | ✓ | string | 触发本轮写入的 session |
| `records[].task_id` | ✗ | string | 关联的任务 ID（如有） |
| `records[].workflow_id` | ✗ | string | 关联的固化工作流（如有） |
| `records[].question` | ✓ | string | 本轮核心问题 |
| `records[].answer` | ✓ | string | 本轮核心答案/结论 |
| `records[].input_time` | ✓ | ISO 8601 | 输入开始时间 |
| `records[].output_time` | ✓ | ISO 8601 | 输出完成时间 |
| `records[].duration_seconds` | ✓ | int | 耗时 |
| `records[].context_version` | ✓ | string | 项目版本 |
| `records[].tags` | ✗ | string[] | 分类标签 |
| `records[].files_touched` | ✗ | string[] | 本轮涉及的文件 |
| `records[].outcome` | ✗ | enum | pass / warn / fail / partial |
| `records[].score` | ✗ | number | 评分（0-100） |
| `records[].key_takeaways` | ✗ | string[] | 关键要点（≤3 条） |

### fix.json 新增字段（在原 AGENTS.md 7.2 基础上）

| 字段 | 必填 | 类型 | 说明 |
|------|------|------|------|
| `task_id` | ✗ | string | 关联任务 ID |
| `workflow_id` | ✗ | string | 关联固化工作流 |
| `duration_minutes` | ✗ | int | 修复耗时 |
| `prevention` | ✗ | string[] | 预防措施 |
| `tags` | ✗ | string[] | 分类标签 |

## 与原 AGENTS.md 7.2 节的关系

| 维度 | 原 7.2 节 | 本规范 |
|------|----------|--------|
| 位置 | `.trea/memory/` | `./.minimax/memory\`（项目级） |
| 触发 | 任务闭环 / 主动结束 | **每轮结束前**强制（更频繁） |
| 范围 | 主 Agent | **所有子 Agent + 任务** |
| 压缩 | 滑动窗口清理 | **递次记忆**（按 memory/fix 分类分层） |
| 唤醒 | 未定义 | **6 条记忆重组仪式**（最新 3+3） |
| 强制力 | 描述性 | **PostToolUse 提醒 + SessionEnd 强校验** |

## 强制约束

- 写入方：**子 Agent 自己**写自己的 memory（你 Q3b 的决定）
- 容量上限：每 Agent 的 memory ≤ 100，fix ≤ 200
- 超限：**自主迁移**最早一条到 `_archive/`
- 启动检查：主 agent 启动时**必须**读 `memory/_schema.md` 和 `memory/_README.md`
- 唤醒协议：见 `memory/_wakeup-protocol.md`
