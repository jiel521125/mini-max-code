# 项目级子 Agent 池

> **位置**：`./.minimax/agents\`
> **归属**：本项目（天枢项目）专用
> **持久化**：`registry.json` 跨 session 保留注册信息

## 职责边界

- 本目录的子 Agent **只在 E:\TianShu\Agent 项目工作流中**被编排
- 与 mavis 全局 Agent 池（`~/.mavis/agents/`）**完全隔离**
- 主 agent（Mavis）启动时**强制扫描并注册**本目录所有子 Agent

## 目录规范

```
agents/
├── README.md           ← 本文件
├── _schema.md          ← manifest 格式定义
├── registry.json       ← 持久化注册表（启动时强制加载）
└── <agent-id>/         ← 每个子 Agent 一个目录
    ├── manifest.json   ← 子 Agent 自描述
    └── [其他文件]      ← 子 Agent 自身的 prompt/工具/示例
```

## 命名规范

- **子 Agent ID**：`<role>-<version>` 格式，全小写、连字符分隔
  - 示例：`code-reviewer-v1`、`api-designer-v1`、`test-generator-v1`
- **目录名**：与子 Agent ID 完全一致
- **避免**：使用 `AGENT-01` 这类带数字的旧风格命名（那是全局 Agent 池的编号）

## 注册机制

### 启动时（强制）

1. 主 agent 读取 `registry.json`
2. 遍历所有 `manifest.json`，校验必填字段
3. 注册到主 agent 的"项目级可调用列表"
4. 注册成功的子 Agent 立即可被工作流编排调用

### 运行中

- 编排工作流时直接引用子 Agent ID：`call: code-reviewer-v1`
- 注册信息已持久化，**session 关闭后不丢失**

### 新增子 Agent

1. 在 `agents/<agent-id>/` 下创建目录
2. 写 `manifest.json`（参考 `_schema.md`）
3. 主 agent 启动时自动扫描到

### 禁用子 Agent

- 在 `manifest.json` 中加 `"enabled": false`
- 启动时会被加载但不会被编排

## registry.json 格式

```json
{
  "schema_version": "1.0.0",
  "last_scan_time": "2026-06-15T18:59:00+08:00",
  "agents": [
    {
      "id": "code-reviewer-v1",
      "role": "code-reviewer",
      "version": "1.0.0",
      "manifest_path": "agents/code-reviewer-v1/manifest.json",
      "enabled": true,
      "registered_at": "2026-06-15T18:59:00+08:00"
    }
  ]
}
```

**关键点**：
- `registry.json` 是**持久化层**，session 关闭不丢
- 下次启动时**先读 `registry.json`**，避免每次全盘扫描
- 启动扫描时若发现 `registry.json` 与实际目录不一致，**以目录为准**（自动同步 registry）

## 强制加载规则

**主 agent 启动时必须按以下顺序加载**：
1. `agents/registry.json`（持久化注册表）
2. `agents/_schema.md`（manifest 格式）
3. 本 README（理解目录结构）
4. 实际存在的每个子 Agent 的 `manifest.json`

**不得遗忘**——此清单已标注在 `~/.mavis/agents/mavis/memory/MEMORY.md` 中作为"项目必读项"。
