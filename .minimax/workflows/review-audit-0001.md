---
workflow_id: review-audit-0001
title: 代码审查审计工作流
category: review
action: audit
version: 1.0.0
created_at: 2026-06-15T21:07:00+08:00
created_by: user
source: dynamic-编排
status: active
triggers:
  - "审查",
  - "review",
  - "audit",
  - "代码审查",
  - "code review",
  - "审计"
description: |
  全量代码审查工作流：拉取变更 → 9 维度审查 → 安全审计 → 输出报告 → 沉淀
---

# 代码审查审计工作流

## 触发场景

- PR/MR 提交前自检
- 重大变更的全量审查
- 定期代码质量审计（周/月）

## 前置条件

- 有具体的代码范围（文件、目录、commit range、PR）
- 审查标准明确（默认 9 维度全开）

## 工作流步骤

### 步骤 1：确定审查范围
- **子 Agent**: 主 agent
- **依赖**: 无
- **输入**: { target: string (path|commit_range|pr_id), scope_description: string }
- **输出**: { files_to_review: string[], estimated_loc: number }
- **成功标准**: 审查范围明确，LOC 估算合理

### 步骤 2：9 维度静态审查
- **子 Agent**: `code-reviewer-v1`（**已注册**）
- **依赖**: 步骤 1
- **输入**: { code_path: string, check_dimensions: ["naming", "structure", "exception", "performance", "security", "testability", "maintainability", "documentation", "boundary"] }
- **输出**: { verdict, score, issues }
- **成功标准**: verdict ∈ {pass, warn}，score ≥ 70
- **失败处理**: verdict=fail → 标记高风险 issue，输出修复建议清单

### 步骤 3：安全审计
- **子 Agent**: `code-reviewer-v1`（**已注册**，限定 security 维度）
- **依赖**: 步骤 1
- **并行**: true（与步骤 2 并行）
- **输入**: { code_path: string, check_dimensions: ["security"], severity_threshold: "warn" }
- **输出**: { vulnerabilities: array<{cwe, severity, location, fix_suggestion}>, security_score: number }
- **成功标准**: 无 critical 漏洞
- **失败处理**: 有 critical → 立即打回，禁止合并

### 步骤 4：生成综合审查报告
- **子 Agent**: 主 agent
- **依赖**: 步骤 2 + 步骤 3
- **输入**: { static_review: object, security_audit: object }
- **输出**: { report_path: string, summary: string, blockers: array, warnings: array, suggestions: array }
- **成功标准**: 报告生成，包含可执行建议

### 步骤 5：通知 + 沉淀
- **子 Agent**: 主 agent
- **依赖**: 步骤 4
- **输入**: { report: object }
- **输出**: 报告交付 + 更新 `rules/audit-history.md`（如存在）
- **成功标准**: 用户收到报告 + 历史已记录

## 输出物清单

- 9 维度审查报告
- 安全审计报告（CWE 分类）
- 综合审查报告
- 审查历史记录

## 异常处理

| 异常类型 | 处理方式 |
|---------|---------|
| 步骤 2 score < 70 | 整体打回，要求修复后再审 |
| 步骤 3 有 critical 漏洞 | 立即打回，标记为安全红线 |
| 审查范围超大（> 5000 LOC） | 拆分为多次审查或抽样审查 |

## 编排理由

- 步骤 2 + 3 并行：静态审查与安全审计互不依赖，节省时间
- 步骤 4 整合两份报告：避免信息碎片
- 步骤 5 沉淀历史：积累审查经验，便于趋势分析

## 版本历史

| 版本 | 时间 | 变更 |
|------|------|------|
| 1.0.0 | 2026-06-15 | 首次固化（v1.0.0 首批工作流） |
