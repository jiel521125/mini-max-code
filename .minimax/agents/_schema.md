# 子 Agent Manifest 格式规范 (Schema v1.0.0)

> **用途**：每个子 Agent 在 `agents/<id>/manifest.json` 中自描述，主 agent 启动时扫描并注册。

## 必填字段

```json
{
  "id": "code-reviewer-v1",
  "role": "code-reviewer",
  "version": "1.0.0",
  "description": "代码审查专家，9 维度检查清单",
  "triggers": ["review", "审查", "代码审查", "code review"],
  "capabilities": [
    "静态代码分析",
    "9 维度质量检查",
    "安全审计"
  ],
  "inputs": {
    "code_path": "string, 必填, 待审查的代码文件路径",
    "check_dimensions": "array<string>, 可选, 默认全 9 维度"
  },
  "outputs": {
    "verdict": "string: pass | warn | fail",
    "issues": "array<issue>",
    "score": "number, 0-100"
  },
  "enabled": true
}
```

## 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | ✓ | 子 Agent 唯一 ID，目录名必须与之一致 |
| `role` | string | ✓ | 角色简写，用于意图粗筛 |
| `version` | string | ✓ | 语义化版本 |
| `description` | string | ✓ | 一句话说明 |
| `triggers` | string[] | ✓ | 触发关键词数组，**用于阶段 1 关键词/正则粗筛** |
| `capabilities` | string[] | ✓ | 能力清单，**用于阶段 2 LLM 推理时的能力匹配** |
| `inputs` | object | ✓ | 输入契约（参数名 + 类型 + 必填 + 说明） |
| `outputs` | object | ✓ | 输出契约 |
| `enabled` | boolean | ✓ | 是否启用，false 的会被加载但不被编排 |
| `dependencies` | string[] | ✗ | 依赖的其他子 Agent ID |
| `tags` | string[] | ✗ | 分类标签，便于聚合 |

## 校验规则

主 agent 启动扫描时**必须**校验：
1. 所有必填字段都存在
2. `id` 与目录名一致
3. `version` 符合 `x.y.z` 格式
4. `triggers` 数组非空
5. `enabled` 字段为布尔

校验失败的子 Agent 会被跳过，并在 `registry.json` 中标记 `load_error`。

## 示例：完整的子 Agent

```json
{
  "id": "api-designer-v1",
  "role": "api-designer",
  "version": "1.0.0",
  "description": "接口设计专家，RESTful/GraphQL 接口规范",
  "triggers": ["api", "接口", "接口设计", "restful", "graphql"],
  "capabilities": [
    "RESTful API 设计",
    "GraphQL Schema 设计",
    "OpenAPI 规范生成",
    "接口版本管理"
  ],
  "inputs": {
    "resource_name": "string, 必填, 资源名（如 user/order）",
    "operations": "array<string>, 必填, [create|read|update|delete|list]",
    "auth_required": "boolean, 可选, 默认 true"
  },
  "outputs": {
    "endpoints": "array<endpoint>",
    "openapi_spec": "object",
    "design_notes": "string"
  },
  "dependencies": [],
  "tags": ["backend", "design"],
  "enabled": true
}
```
