# 天枢多智能体调度系统 (TianShu Agent)

> **专为 MinimaxCode 打造的项目级 AI 工作流引擎与防漂移记忆体系。**
> 装上 `.minimax/`，让 MinimaxCode 在多轮对话中不再漂移、工作流可复用、上下文可永久沉淀。

---

## 这是什么

本系统是 **MinimaxCode IDE 的协同运行时**——通过 `.minimax/` 目录为你的项目注入三大能力：

1. **双模式工作流引擎** —— 固化模板（关键词命中即用）+ 动态编排（每次 ≤3 候选，你选一个）
2. **项目级子 Agent 池** —— 4 个开箱即用的专业角色：代码审查、接口设计、测试生成、业务编码
3. **防漂移记忆体系** —— 每轮对话自动写 memory、修复经验自动写 fix，下次唤醒自动恢复上下文

**和 MinimaxCode 的关系**：
- MinimaxCode = 你的**编辑器**（负责代码改写）
- 本系统 = 你的**工作流引擎 + 长期记忆库**（负责流程标准化和上下文管理）
- 两者通过 `.minimax/` 协同，**不切换 IDE、不打断你写代码**

---

## 解决 MinimaxCode 的 3 个核心痛点

| 痛点 | 现象 | 本系统的解法 |
|------|------|-------------|
| **多轮对话会"漂移"** | 聊 5 轮后 LLM 忘事、修复的 Bug 反复出现、经验没沉淀 | 每个 Agent 维护 `memory.json`（100 条）+ `fix.json`（200 条），唤醒时自动重读最新 3+3 条 |
| **工作流每次从零开始** | 没人知道项目里有哪些规范流程、新人入职成本高 | 4 个固化工作流（feature/bugfix/review/deploy） + 动态→固化转化机制 |
| **单 Agent 啥都干，啥都不精** | 接口设计/测试/审查让一个 LLM 干，结果是"啥都懂一点" | 4 个专业子 Agent（code-reviewer / api-designer / test-generator / coder），独立调优、按需组合 |

**额外价值**：跨项目即拿即用（`.minimax/` 整目录复用）、CI/CD 自动化（GitHub + Gitea Actions）、跨平台（Win/Mac/Linux）、Docker 化、可观测（决策日志 + 启动 metadata + 归档）。

---

## 5 分钟上手

```bash
# 1. 拷到项目根
cp -r /path/to/.minimax ./

# 2. 装到 mavis
cd .minimax && ./scripts/install.sh

# 3. 启动 MinimaxCode，对它说：
"读 .minimax/README.md 了解工作流，读 .minimax/memory/_README.md 了解记忆体"

# 完成
```

日常使用：在 MinimaxCode 里写代码，**后台 mavis 跑子 Agent 编排 + 记忆体**，两者通过 `.minimax/` 共享。

应急跳过：
```bash
MAVIS_PROJECT_BOOTSTRAP_SKIP=1 mavis ...   # 跳过启动校验
MAVIS_MEMORY_ENFORCE_SKIP=1 mavis ...       # 跳过记忆强校验
```

---

## 项目结构

```
your-project/
├── AGENTS.md / CLAUDE.md / ...  ← MinimaxCode / mavis 框架文件（不动）
└── .minimax/                    ← 本系统（55 个文件，封装一切）
    ├── README.md                详细使用文档
    ├── project.json             元数据
    ├── config/                  路径抽象 + 跨平台配置
    ├── scripts/                 install / uninstall / migrate / export
    ├── hooks/                   MinimaxCode session 启动 + 记忆强制
    ├── agents/                  4 个子 Agent（manifest + prompt）
    ├── workflows/               4 个固化工作流 + 双模式引擎
    ├── rules/                   决策日志
    ├── memory/                  防漂移记忆体（5 个 Agent × memory/fix）
    ├── .github/ .gitea/         CI/CD
    ├── Dockerfile + docker-compose
    └── LICENSE + CHANGELOG
```

---

## 如何迁移

```bash
# 跨机器
./.minimax/scripts/export.sh /tmp/proj.zip
# 拷到新机器，unzip + ./install.sh

# 跨项目
cp -r /old/.minimax /new-project/

# 卸载
./.minimax/scripts/uninstall.sh  # 注销 hook，再删目录
```

---

## 核心特性

### 🚀 部署与迁移
- **即拿即用** —— `.minimax/` 整目录迁移，30 秒装好
- **相对路径** —— 所有引用都是相对路径，不依赖具体工作目录
- **跨平台** —— Windows / macOS / Linux 统一
- **Docker 化** —— Dockerfile + docker-compose，容器内运行

### 🧠 AI 能力
- **防漂移** —— 记忆体（100/200 上限）+ 6 条重组（3+3），永远不丢上下文
- **固化 + 柔性** —— 关键词命中用固化模板，命中不到用 LLM 编排候选
- **专业分工** —— 4 个独立子 Agent：代码审查 / 接口设计 / 测试生成 / 业务编码
- **持久化注册** —— 子 Agent 注册表跨 session 保留

### 🛡️ 可靠性
- **强制约束** —— SessionStart 校验必读文件 + SessionEnd 校验记忆写入
- **CI/CD** —— GitHub + Gitea Actions 自动校验
- **可观测** —— 决策日志 + metadata 注入 + 归档
- **可回滚** —— `uninstall.sh` + `mavis-trash` 干净回退

---

## 维护

- **作者**：TianShu (天枢) <1033085514@qq.com>
- **微信**：1033085514
- **许可**：MIT
- **最后更新**：2026-06-15
- **版本**：v1.1.0

---

## 💖 支持本框架

如果您觉得我的方法论有用，那就请我喝杯茶吧  :blush: ！

<table>
  <tr>
    <td style="text-align: center; padding: 10px;">
      <img src="https://gitee.com/jiel521125/mini-max-code/raw/master/pay1.jpg" alt="龙麟之心" width="200">
    </td>
    <td style="text-align: center; padding: 10px;">
      <img src="https://gitee.com/jiel521125/mini-max-code/raw/master/pay2.jpg" alt="键盘先森" width="200">
    </td>
  </tr>
</table>

---

**下一步**：
- 📖 [`.minimax/README.md`](./.minimax/README.md) — 详细使用文档
- 🛠️ [`.minimax/workflows/README.md`](./.minimax/workflows/README.md) — 双模式工作流引擎
- 🧠 [`.minimax/memory/_README.md`](./.minimax/memory/_README.md) — 防漂移记忆体
- 🚀 `./.minimax/scripts/install.sh` — 装上跑起来
