# Changelog

所有本项目的显著变更都会记录在此文件。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2026-06-15

### 新增
- **双模式工作流引擎**
  - 阶段 1：关键词/正则粗筛（命中固化模板）
  - 阶段 2：LLM 推理编排（输出 ≤3 个候选 + 编排理由）
  - 双阶段**并行**执行，不是串行
- **项目级子 Agent 池** (`agents/`)
  - manifest.json 自描述规范
  - registry.json 持久化注册表（跨 session 不丢）
  - 自动扫描注册机制
- **固化工作流模板库** (`workflows/`)
  - `_template.md` 标准化 schema
  - `_intent-router.md` 双阶段判别规则
  - `INDEX.md` 自动维护索引
  - 固化后在本项目内不可变
- **动态 → 固化决策日志** (`rules/workflow-decisions.md`)
- **SessionStart 硬约束 hook** (`hooks/project-bootstrap-check.md`)
  - 启动时强制校验 13 个必读文件
  - 应急逃生：`MAVIS_PROJECT_BOOTSTRAP_SKIP=1`
- **配置抽象层** (`config/`)
  - `paths.json` 路径真理源
  - `platform.json` 跨平台差异映射（Windows/macOS/Linux）
- **运维脚本** (`scripts/`)
  - `install.sh` 一键安装
  - `uninstall.sh` 一键卸载
  - `migrate.sh` 一站式迁移
  - `export.sh` 打包导出
- **项目入口与元数据**
  - `README.md` 人读入口
  - `project.json` 项目元数据
  - `.gitignore` Git 忽略规则
  - `LICENSE` MIT 许可
  - `CHANGELOG.md` 本文件

### 子 Agent（v1.0.0 首批）
- `code-reviewer-v1` — 9 维度代码审查
- `api-designer-v1` — RESTful/GraphQL 接口设计
- `test-generator-v1` — 自动化测试生成
- `coder-v1` — 业务逻辑编码

### 固化工作流（v1.0.0 首批）
- `feature-develop-0001` — 新功能开发标准工作流
- `bugfix-investigate-0001` — Bug 调查修复工作流
- `review-audit-0001` — 代码审查审计工作流
- `deploy-release-0001` — 部署发布工作流

### CI/CD
- GitHub Actions 工作流（`.github/workflows/ci.yml`）
- Gitea Actions 工作流（`.gitea/workflows/ci.yml`）

### Docker
- `Dockerfile` 容器化构建
- `docker-compose.yml` 容器编排
- `.dockerignore` 构建忽略

### 文档
- `agents/README.md` 子 Agent 池规范
- `agents/_schema.md` manifest 字段规范
- `workflows/README.md` 双模式引擎总览
- `workflows/_template.md` 固化工作流 schema
- `workflows/_intent-router.md` 意图判别规则
- `rules/workflow-decisions.md` 决策日志

### 技术约束
- 主 agent 强制加载 13 个必读文件（写入 mavis MEMORY.md）
- Hook 校验必读文件，任一缺失 → abort session
- 子 Agent 命名规范：`<role>-<version>`，全小写、连字符
- 工作流命名规范：`<category>-<action>-<seq>`

### 维护
- 作者：TianShu (天枢) <1033085514@qq.com>
- 许可：MIT
