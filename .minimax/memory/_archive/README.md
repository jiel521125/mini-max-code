# 压缩归档索引

> **位置**：`./.minimax/memory\_archive\`
> **职责**：存放被压缩迁移的历史记录
> **组织**：按 memory/fix 分类，按 agent-id 分目录，按季度分层

## 目录结构

```
_archive/
├── memory/
│   ├── mavis/
│   │   ├── layer-1-2026-Q3.json
│   │   └── ...
│   ├── code-reviewer-v1/
│   │   └── layer-1-2026-Q3.json
│   ├── api-designer-v1/
│   ├── test-generator-v1/
│   └── coder-v1/
└── fix/
    ├── mavis/
    │   └── layer-1-2026-Q3.json
    ├── code-reviewer-v1/
    │   └── layer-1-2026-Q3.json
    ├── api-designer-v1/
    ├── test-generator-v1/
    └── coder-v1/
```

## 当前状态

_尚无归档记录_

## 归档规则

详见 [`_compress.md`](./_compress.md)：

- memory 活跃层 ≤ 100 条
- fix 活跃层 ≤ 200 条
- 超限迁移最早一条到对应 `_archive/` 子目录
- 单层容量 100/200 条
- 季度归并，跨季度重置层号

## 召回方式

子 Agent 默认不主动查归档。仅在以下情况查：

- 显式指定 `load_recent_count` 大于活跃层容量
- 显式指定时间范围（如"找 2026-Q2 的某条记录"）
- 主 agent 显式要求"回溯"

## 数据完整性

- 归档记录**永不删除**（除非用户显式要求）
- 跨机器迁移时 `_archive/` 整体随项目打包
- 单个归档文件可能很大，定期（每季度？）可考虑二进制压缩
