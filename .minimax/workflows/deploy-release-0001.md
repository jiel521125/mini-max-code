---
workflow_id: deploy-release-0001
title: 部署发布工作流
category: deploy
action: release
version: 1.0.0
created_at: 2026-06-15T21:07:00+08:00
created_by: user
source: dynamic-编排
status: active
triggers:
  - "deploy",
  - "部署",
  - "release",
  - "发布",
  - "上线",
  - "部署发布"
description: |
  标准化部署发布流程：构建 → 验证 → 预发 → 生产 → 监控 → 沉淀
---

# 部署发布工作流

## 触发场景

- 版本号发布
- 紧急修复上线（hotfix）
- 阶段性功能上线

## 前置条件

- 改动已合并到 main/release 分支
- 版本号已确定（语义化版本）
- 部署环境（dev/staging/prod）已配置

## 工作流步骤

### 步骤 1：构建验证
- **子 Agent**: 主 agent
- **依赖**: 无
- **输入**: { version: string, branch: string }
- **输出**: { build_status: "success|fail", artifacts: string[] }
- **成功标准**: 构建成功 + 产物生成
- **失败处理**: 构建失败 → 打回，修复后重试

### 步骤 2：自动化测试
- **子 Agent**: 主 agent
- **依赖**: 步骤 1
- **输入**: { test_types: ["unit", "integration", "e2e"] }
- **输出**: { test_results: object, coverage: number }
- **成功标准**: 全部测试通过 + 覆盖率 ≥ 80%

### 步骤 3：代码审查（发布前）
- **子 Agent**: `code-reviewer-v1`（**已注册**）
- **依赖**: 步骤 1
- **并行**: true（与步骤 2 并行）
- **输入**: { code_path: "本次发布的所有改动" }
- **输出**: { verdict, issues }
- **成功标准**: verdict ≠ "fail"

### 步骤 4：预发部署 + 冒烟
- **子 Agent**: 主 agent
- **依赖**: 步骤 2 + 步骤 3
- **输入**: { env: "staging", version: string }
- **输出**: { deploy_status, smoke_test_results }
- **成功标准**: 部署成功 + 冒烟测试通过

### 步骤 5：生产部署（蓝绿/灰度）
- **子 Agent**: 主 agent
- **依赖**: 步骤 4
- **输入**: { env: "production", strategy: "blue-green|canary|rolling", traffic_percentage?: number }
- **输出**: { deploy_status, traffic_split?: object, rollback_ready: bool }
- **成功标准**: 部署成功 + 回滚方案就绪
- **失败处理**: 异常告警 → 立即回滚

### 步骤 6：生产监控（24h）
- **子 Agent**: 主 agent
- **依赖**: 步骤 5
- **输入**: { monitoring_window_hours: 24 }
- **输出**: { error_rate, latency_p99, alert_count, status: "healthy|degraded|critical" }
- **成功标准**: 24h 内无 critical 告警
- **失败处理**: 异常 → 评估是否回滚

### 步骤 7：发布总结 + 沉淀
- **子 Agent**: 主 agent
- **依赖**: 步骤 6
- **输入**: { all_outputs }
- **输出**: { release_notes_path, changelog_update, deployment_record }
- **成功标准**: release notes 发布 + CHANGELOG.md 更新

## 输出物清单

- 构建产物
- 测试报告
- 审查报告
- 部署记录
- 监控数据
- Release notes
- CHANGELOG 更新

## 异常处理

| 异常类型 | 处理方式 |
|---------|---------|
| 步骤 1 构建失败 | 打回修复 |
| 步骤 2 测试失败 | 打回修复 |
| 步骤 3 审查 fail | 打回修复 |
| 步骤 4 冒烟失败 | 回滚到上一个版本 |
| 步骤 5 生产异常 | 立即回滚 + 告警 |
| 步骤 6 24h 监控告警 | 评估是否回滚 |

## 编排理由

- 步骤 2 + 3 并行：测试与审查互不依赖
- 步骤 4 预发：降低生产风险
- 步骤 5 蓝绿/灰度：避免一次性全量切换
- 步骤 6 24h 监控：发现延迟问题
- 步骤 7 沉淀：积累发布经验

## 版本历史

| 版本 | 时间 | 变更 |
|------|------|------|
| 1.0.0 | 2026-06-15 | 首次固化（v1.0.0 首批工作流） |
