# 天枢多智能体调度系统 (TianShu Agent)

> **项目 ID**: tianshu-agent-001
> **版本**: 1.0.0
> **状态**: Active
> **作者**: TianShu (天枢) <1033085514@qq.com>

## 这是什么

一个**项目级**的多智能体调度系统，基于 mavis 框架构建。包含：

- **子 Agent 池** (`agents/`)：可被编排的角色单元（代码审查、API 设计、测试生成等）
- **固化工作流模板库** (`workflows/`)：项目内已锁定的执行模板
- **双模式工作流引擎**：固化（阶段 1 关键词粗筛）+ 动态（阶段 2 LLM 推理编排 ≤3 候选）
- **意图判别 + 子 Agent 编排 + 决策沉淀**的完整闭环

**与 mavis 全局 agent 池隔离**——本项目自包含、可独立迁移。

## 5 分钟上手

### 前置条件

- **mavis** 框架（>= 0.5.0），运行中的 daemon
- **bash**（Git Bash / WSL / Linux / macOS 均可）
- 操作系统：Windows 10+ / macOS 10.15+ / Linux（任意主流发行版）

### 安装（在新机器上）

```bash
# 1. 把整个项目目录拷过来（git clone / scp / zip 解压均可）
cd /path/to/Agent

# 2. 跑 install 脚本
./scripts/install.sh

# 3. 验证
mavis hook list | grep project-bootstrap-check
# 应输出: mavis:project-bootstrap-check
```

### 第一次使用

启动 mavis session（任何 mavis 客户端）：

1. SessionStart 时会自动触发 `mavis:project-bootstrap-check` hook
2. 校验 8 个必读文件全在 → 放行 + 注入 metadata
3. 你的输入会经过双阶段意图判别（关键词粗筛 + LLM 推理）
4. 主 agent 展示 ≤3 个候选工作流 + 编排理由
5. 你选 → 执行 → 若选动态候选则自动固化为新模板

### 应急逃生

如果项目文件被破坏、想临时跳过启动校验：

```bash
# Windows PowerShell
$env:MAVIS_PROJECT_BOOTSTRAP_SKIP = "1"
mavis ...

# Linux / macOS / Git Bash
MAVIS_PROJECT_BOOTSTRAP_SKIP=1 mavis ...
```

## 目录结构

```
Agent/
├── README.md               ← 本文件（人读入口）
├── project.json            ← 项目元数据
├── AGENTS.md               ← mavis agent 系统提示（不迭代）
├── CLAUDE.md               ← 底层模型配置（不迭代）
├── .gitignore              ← Git 忽略规则
│
├── agents/                 ← 子 Agent 池
│   ├── README.md
│   ├── _schema.md
│   ├── registry.json       ← 持久化注册表
│   └── <agent-id>/
│       ├── manifest.json   ← 子 Agent 自描述
│       └── prompt.md       ← 子 Agent 提示词
│
├── workflows/              ← 固化工作流模板库
│   ├── README.md
│   ├── _template.md        ← 固化工作流 schema
│   ├── _intent-router.md   ← 双阶段意图判别规则
│   ├── INDEX.md            ← 固化模板索引（自动维护）
│   └── <workflow-id>.md    ← 具体工作流
│
├── rules/                  ← 项目规则归档
│   └── workflow-decisions.md  ← 动态→固化的决策日志
│
├── config/                 ← 配置（跨平台、路径抽象）
│   ├── paths.json
│   └── platform.json
│
└── scripts/                ← 运维脚本
    ├── install.sh
    ├── uninstall.sh
    ├── migrate.sh
    └── export.sh
```

## 如何添加子 Agent

1. 在 `agents/<agent-id>/` 下创建目录（id 格式：`<role>-<version>`，全小写、连字符）
2. 写 `manifest.json`，参考 `agents/_schema.md`
3. 写 `prompt.md`，定义子 Agent 的行为
4. 跑 `./scripts/install.sh`（或在主 agent 启动时自动扫描注册）

**禁止**：
- 使用 `AGENT-01` 这类数字编号（那是 mavis 全局 Agent 池的风格）
- 修改其他子 Agent 的目录（除非你是该 Agent 的负责人）

## 如何固化工作流

1. **通过动态编排**：
   - 主 agent 阶段 2 推理出 ≤3 个候选
   - 你选择其一
   - 主 agent 按 `workflows/_template.md` 固化为 `workflows/<workflow-id>.md`
   - 同步追加到 `workflows/INDEX.md` 和 `rules/workflow-decisions.md`

2. **直接指示**："这个流程以后就这么走"
   - 主 agent 现场编排出工作流
   - 展示给你确认
   - 确认后按同样流程固化

3. **重复任务识别**（自动）
   - 同一类任务被动态编排 ≥3 次
   - 主 agent 主动建议固化

**固化后不可变**——在本项目内是 immutable 的，避免上下文抖动。

## 迁移到新机器

```bash
# 在源机器上
cd /path/to/Agent
./scripts/export.sh /tmp/tianshu-agent.zip

# 把 zip 拷到新机器（scp / 共享盘 / U 盘均可）

# 在新机器上
unzip tianshu-agent.zip -d /new/path/
cd /new/path/Agent
./scripts/install.sh
```

## 跨平台说明

| 平台 | shell | 路径分隔符 | 备注 |
|------|-------|-----------|------|
| Windows | Git Bash / WSL | `/` 或 `\` | 推荐用 Git Bash |
| macOS | zsh / bash | `/` | 任意 shell |
| Linux | bash | `/` | 任意 shell |

`config/platform.json` 包含平台差异映射，hook 脚本会自动判断。

## 应急与回滚

| 场景 | 操作 |
|------|------|
| 启动校验失败 | 设置 `MAVIS_PROJECT_BOOTSTRAP_SKIP=1` 临时跳过 |
| Hook 行为异常 | `mavis hook delete mavis:project-bootstrap-check` 卸载 |
| 完全卸载 | 跑 `./scripts/uninstall.sh` |
| 项目数据损坏 | 从最近的 `export` 备份恢复 |

## 维护责任人

- **架构 & 决策**：TianShu (天枢)
- **子 Agent 维护**：每个子 Agent 的 owner（在 `manifest.json` 的 `maintainer` 字段）
- **工作流固化**：主 agent 自动 + 用户确认

## 许可

MIT License (3.0) — 详见 LICENSE 文件

## 联系

- **作者**: TianShu (天枢)
- **邮箱**: 1033085514@qq.com
- **微信**: 1033085514
- **最后更新**: 2026-06-15
