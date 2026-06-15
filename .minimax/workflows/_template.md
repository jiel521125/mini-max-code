# 固化工作流模板 (Schema v1.0.0)

> **用途**：动态编排的工作流被用户确认后，**按此格式**固化为项目级工作流模板。
> **位置**：`./.minimax/workflows\<workflow-id>.md`

## 完整 Schema

```markdown
---
workflow_id: feature-develop-0001
title: 新功能开发标准工作流
category: feature
action: develop
version: 1.0.0
created_at: 2026-06-15T18:59:00+08:00
created_by: user
source: dynamic-编排
status: active
triggers:
  - "新功能"
  - "开发"
  - "feature"
  - "实现"
description: |
  标准的新功能开发流程：需求澄清 → 架构设计 → 编码 → 测试 → 沉淀
---

# 新功能开发标准工作流

## 触发场景

[描述此工作流适用于什么样的用户输入]

## 前置条件

- [必须满足的条件 1]
- [必须满足的条件 2]

## 工作流步骤

### 步骤 1：[步骤名]
- **子 Agent**: `<agent-id>`
- **输入**: [参数契约]
- **输出**: [产出物]
- **成功标准**: [如何判定此步成功]
- **失败处理**: [失败后怎么办]

### 步骤 2：[步骤名]
- **子 Agent**: `<agent-id>`
- **依赖**: 步骤 1
- **输入**: [参数契约]
- **输出**: [产出物]
- **成功标准**: [如何判定此步成功]
- **失败处理**: [失败后怎么办]

### 步骤 3：[步骤名]（可选并行步骤）
- **子 Agent**: `<agent-id>`
- **依赖**: 步骤 2
- **并行**: true
- **输入**: [参数契约]
- **输出**: [产出物]

## 输出物清单

- [产出物 1]
- [产出物 2]
- [产出物 3]

## 异常处理

| 异常类型 | 处理方式 |
|---------|---------|
| 子 Agent 不可用 | 降级到备选 Agent |
| 步骤 1 失败 2 次 | 升级人工介入 |
| 用户中途变更 | 重新编排，覆盖本工作流 |

## 版本历史

| 版本 | 时间 | 变更 |
|------|------|------|
| 1.0.0 | 2026-06-15 | 首次固化 |
```

## 字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| `workflow_id` | ✓ | 唯一 ID，格式：`<category>-<action>-<seq>` |
| `title` | ✓ | 人类可读标题 |
| `category` | ✓ | feature/bugfix/research/review/deploy/doc |
| `action` | ✓ | develop/fix/investigate/audit/release/write |
| `version` | ✓ | 语义化版本 |
| `triggers` | ✓ | 触发关键词数组，**用于阶段 1 粗筛** |
| `description` | ✓ | 详细说明 |
| `status` | ✓ | active/deprecated/draft |
| `source` | ✓ | dynamic-编排 / user-direct / repeated-task |
| `created_by` | ✓ | user / agent |
| `created_at` | ✓ | ISO 8601 时间戳 |

## 步骤字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| `子 Agent` | ✓ | 必须是在 `agents/registry.json` 中已注册的子 Agent ID |
| `输入` | ✓ | 参数契约 |
| `输出` | ✓ | 产出物 |
| `依赖` | ✗ | 依赖的前置步骤 ID |
| `并行` | ✗ | 默认为 false，true 表示可与同层其他步骤并行 |
| `成功标准` | ✓ | 判定此步成功的标准 |
| `失败处理` | ✓ | 失败后的处理方式 |

## 固化流程（动态 → 固化）

```
1. 主 agent 阶段 2 推理出 ≤3 个动态候选
2. 展示给用户 + 每个候选附"为什么这样编排"
3. 用户选择某一候选（或自定义修改）
4. 主 agent 按本 schema 生成工作流文件
5. 写入 ./.minimax/workflows\<workflow-id>.md
6. 追加到 INDEX.md
7. 追加决策记录到 ./.minimax/rules\workflow-decisions.md
8. 通知用户："已固化为 [workflow-id]，下次同类输入直接命中"
```

## 强制约束

- **每个工作流步骤必须引用已注册的子 Agent**——不可引用不存在的 Agent
- **triggers 必须非空**——否则阶段 1 无法粗筛命中
- **失败处理必须明确**——不可省略
- **状态变更必须记录**——版本历史不可跳号
