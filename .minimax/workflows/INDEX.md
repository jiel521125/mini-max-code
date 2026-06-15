# 固化工作流索引

> **位置**：`./.minimax/workflows\INDEX.md`
> **职责**：列出所有 active 状态的固化工作流，供阶段 1 粗筛使用
> **维护**：主 agent 动态维护（新增/废弃/更新时同步）

## 当前已固化的工作流

| workflow_id | title | category | triggers | created_at | status |
|------------|-------|----------|----------|------------|--------|
| feature-develop-0001 | 新功能开发标准工作流 | feature | 新功能, 开发, 实现, feature, add feature, implement | 2026-06-15T20:48:00+08:00 | active |
| bugfix-investigate-0001 | Bug 调查修复工作流 | bugfix | bug, fix, 修复, bug修复, 调查, 错误, 异常, 故障 | 2026-06-15T21:07:00+08:00 | active |
| review-audit-0001 | 代码审查审计工作流 | review | 审查, review, audit, 代码审查, code review, 审计 | 2026-06-15T21:07:00+08:00 | active |
| deploy-release-0001 | 部署发布工作流 | deploy | deploy, 部署, release, 发布, 上线, 部署发布 | 2026-06-15T21:07:00+08:00 | active |

## 维护规则

- **新增固化工作流**：在表中追加一行，从 `workflows/<workflow-id>.md` 同步 `triggers` 字段
- **废弃工作流**：将 `status` 改为 `deprecated`，保留行不删除
- **更新工作流**：更新对应行的 `created_at` 为最新版本时间，并更新 `triggers`（如变更）
- **删除工作流**：将 `status` 改为 `deprecated` 后归档，不真删

## 阶段 1 粗筛使用方式

主 agent 阶段 1 粗筛时：
1. 读本文件的 `triggers` 列
2. 对用户输入做关键词/正则匹配
3. 匹配 `status = active` 的行
4. 命中后按需加载 `workflows/<workflow-id>.md` 详细内容

## 统计

- 总数：4
- 按 category：feature (1), bugfix (1), review (1), deploy (1)
- 子 Agent 引用：code-reviewer-v1 (3), coder-v1 (2), test-generator-v1 (2), api-designer-v1 (0)
