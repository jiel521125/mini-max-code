---
workflow_id: bugfix-investigate-0001
title: Bug 调查修复工作流
category: bugfix
action: investigate
version: 1.0.0
created_at: 2026-06-15T21:07:00+08:00
created_by: user
source: dynamic-编排
status: active
triggers:
  - "bug"
  - "fix"
  - "修复"
  - "bug修复"
  - "调查"
  - "错误"
  - "异常"
  - "故障"
description: |
  标准 Bug 调查修复流程：复现 → 定位 → 修复 → 回归测试 → 沉淀
  适用于生产环境的 Bug 修复，2 小时内闭环。
---

# Bug 调查修复工作流

## 触发场景

用户报告 Bug / 监控告警 / 单元测试失败，需要调查并修复。

## 前置条件

- 有可复现的 Bug 描述（堆栈、日志、截图、复现步骤）
- 影响范围已知或可推断

## 工作流步骤

### 步骤 1：复现 + 影响评估
- **子 Agent**: 主 agent
- **依赖**: 无
- **输入**: { bug_report: string, repro_steps: string[], severity: string }
- **输出**: { repro_confirmed: bool, impact_scope: string, estimated_effort: string }
- **成功标准**: 能复现 + 影响范围明确
- **失败处理**: 无法复现 → 索取更多日志/截图

### 步骤 2：定位根因
- **子 Agent**: 主 agent + code-reviewer-v1（静态分析）
- **依赖**: 步骤 1
- **输入**: { repro_steps: string[], affected_files: string[] }
- **输出**: { root_cause: string, root_cause_file?: string, root_cause_line?: number, fix_strategy: string }
- **成功标准**: 根因明确，给出修复策略
- **失败处理**: 根因不清 → 加日志/加断点复现，或请求用户参与

### 步骤 3：写修复
- **子 Agent**: `coder-v1`（**已注册**）
- **依赖**: 步骤 2
- **输入**: { fix_strategy: string, target_files: string[], include_tests: true }
- **输出**: { code_files: string[], test_files: string[] }
- **成功标准**: 编译通过 + 修复测试通过 + 回归测试通过
- **失败处理**: 修复引入新问题 → 回到步骤 2 重新分析

### 步骤 4：回归测试（步骤 3 的并行补充）
- **子 Agent**: `test-generator-v1`（**已注册**）
- **依赖**: 步骤 3
- **并行**: true
- **输入**: { code_path: string, test_type: "integration", coverage_target: 80 }
- **输出**: { test_files: string[], coverage_report: object }
- **成功标准**: 覆盖率达标，回归测试通过

### 步骤 5：代码审查
- **子 Agent**: `code-reviewer-v1`（**已注册**）
- **依赖**: 步骤 3
- **并行**: true（与步骤 4 并行）
- **输入**: { code_path: string, severity_threshold: "warn" }
- **输出**: { verdict: "pass|warn|fail", issues: array }
- **成功标准**: verdict ≠ "fail"

### 步骤 6：沉淀修复经验
- **子 Agent**: 主 agent
- **依赖**: 步骤 4 + 步骤 5
- **输入**: { all_outputs: object }
- **输出**: 追加到 `rules/fix-experience.md`（如存在）或 `workflow-decisions.md` 的 fix 区
- **成功标准**: 经验已记录（包含根因、修复方法、预防措施）

## 输出物清单

- Bug 复现报告
- 根因分析
- 修复代码（含 commit）
- 回归测试用例
- 修复经验沉淀

## 异常处理

| 异常类型 | 处理方式 |
|---------|---------|
| 无法复现 | 升级用户参与调查 |
| 根因不明 | 加日志/断点 → 重新跑步骤 1 |
| 修复影响范围超预期 | 回到步骤 2 重新评估 |
| 步骤 5 审查 fail | 打回步骤 3，按 issues 修复后重审 |

## 编排理由

- 步骤 3 引入 `coder-v1`：自动编码+自动写测试
- 步骤 4、5 并行：测试生成与代码审查互不依赖，节省时间
- 步骤 6 强制沉淀：避免同类 Bug 重复发生

## 版本历史

| 版本 | 时间 | 变更 |
|------|------|------|
| 1.0.0 | 2026-06-15 | 首次固化（v1.0.0 首批工作流） |
