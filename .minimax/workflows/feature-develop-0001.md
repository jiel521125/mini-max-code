---
workflow_id: feature-develop-0001
title: 新功能开发标准工作流
category: feature
action: develop
version: 1.0.0
created_at: 2026-06-15T20:48:00+08:00
created_by: user
source: dynamic-编排
status: active
triggers:
  - "新功能"
  - "开发"
  - "实现"
  - "feature"
  - "add feature"
  - "implement"
description: |
  标准的新功能开发流程：需求澄清 → 架构设计 → 编码 → 测试 → 代码审查 → 沉淀
  适用于中等复杂度的功能开发（工作量 1-3 天）。
---

# 新功能开发标准工作流

## 触发场景

用户输入包含"新功能/开发/实现/feature/implement"等关键词，且任务工作量估计在 1-3 天内的功能开发。

**不适用**：
- 重大架构变更（需 feature-develop-0002 重型工作流）
- Bug 修复（用 bugfix-* 系列）
- 纯文档/配置变更（用 doc-* 系列）

## 前置条件

- 用户已明确功能目标（哪怕是粗略的）
- 知道影响哪些模块/文件
- 紧急程度已确认

## 工作流步骤

### 步骤 1：需求澄清
- **子 Agent**: （待用户注册，本工作流示例先以主 agent 直接执行为准）
- **依赖**: 无
- **输入**: { feature_description: string, acceptance_criteria: string[] }
- **输出**: { user_story: string, acceptance_criteria: string[], estimated_effort: string }
- **成功标准**: 用户故事清晰、验收标准可测试
- **失败处理**: 用户无法澄清 → 标记 pending_review

### 步骤 2：架构/接口设计（轻量）
- **子 Agent**: （待注册，或主 agent 执行）
- **依赖**: 步骤 1
- **输入**: { user_story: string }
- **输出**: { design_notes: string, interface_sketch: string, db_changes?: string }
- **成功标准**: 接口和数据库变更明确
- **失败处理**: 设计有歧义 → 回到步骤 1

### 步骤 3：编码实现
- **子 Agent**: （待注册 coder，或主 agent 协助）
- **依赖**: 步骤 2
- **输入**: { design_notes: string, code_target: string }
- **输出**: { code_files: string[], commit_hash: string }
- **成功标准**: 编译通过 + 核心功能跑通
- **失败处理**: 编译失败 → 重试 2 次后人工介入

### 步骤 4：自动化测试
- **子 Agent**: （待注册 test-generator）
- **依赖**: 步骤 3
- **输入**: { code_files: string[] }
- **输出**: { test_files: string[], coverage: number }
- **成功标准**: 覆盖率 ≥ 80%，核心路径有测试

### 步骤 5：代码审查
- **子 Agent**: `code-reviewer-v1`（**已注册，可直接调用**）
- **依赖**: 步骤 3（与步骤 4 并行）
- **并行**: true
- **输入**: { code_path: string, severity_threshold: "warn" }
- **输出**: { verdict: "pass|warn|fail", score: 0-100, issues: array }
- **成功标准**: verdict ≠ "fail"
- **失败处理**: verdict = fail → 打回步骤 3 修复后重审

### 步骤 6：沉淀（文档/记忆）
- **子 Agent**: 主 agent
- **依赖**: 步骤 4 + 步骤 5
- **输入**: { all_outputs: object }
- **输出**: 更新 `function.md` 任务完成记录表
- **成功标准**: 记录表追加成功

## 输出物清单

- 用户故事文档
- 设计笔记
- 代码文件（含 commit）
- 测试文件 + 覆盖率报告
- 代码审查报告
- 任务完成记录

## 异常处理

| 异常类型 | 处理方式 |
|---------|---------|
| 步骤 1 需求始终澄清不了 | 升级人工介入，写入 `pending_review.md` |
| 步骤 3 编码编译失败 2 次 | 降级或换备选 Agent / 人工 |
| 步骤 5 审查 fail | 打回步骤 3，按 issues 修复后重审 |
| 用户中途变更需求 | 重新评估，重新跑步骤 1 |

## 编排理由

用户选择采纳此候选的核心理由：
1. **步骤 5 用 code-reviewer-v1 做 9 维度审查**：质量门禁前置，尽早发现问题
2. **步骤 4 和 5 并行**：测试与审查互不依赖，节省时间
3. **步骤 6 强制沉淀**：保持文档与代码同步，避免"做完就忘"

## 版本历史

| 版本 | 时间 | 变更 |
|------|------|------|
| 1.0.0 | 2026-06-15 | 首次固化（动态候选采纳） |
