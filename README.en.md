# TianShu Multi-Agent Orchestration System

> **A project-level AI workflow engine and anti-drift memory system, purpose-built for MinimaxCode.**
> Drop in `.minimax/` and MinimaxCode stops drifting across multi-turn conversations, gains reusable workflows, and retains context permanently.

---

## What is this

This system is the **co-runtime for MinimaxCode IDE** — it injects three capabilities into your project through the `.minimax/` directory:

1. **Dual-mode workflow engine** — Pre-defined templates (triggered by keywords) + dynamic orchestration (≤3 candidates per turn, you pick one)
2. **Project-level sub-agent pool** — 4 ready-to-use specialized roles: code reviewer, API designer, test generator, business coder
3. **Anti-drift memory system** — Every conversation auto-writes to `memory`, every fix experience auto-writes to `fix`, context is restored automatically on next wake-up

**Relationship with MinimaxCode**:
- MinimaxCode = your **editor** (handles code rewriting)
- This system = your **workflow engine + long-term memory store** (handles process standardization and context management)
- They coordinate through `.minimax/` — **no IDE switching, no code-writing interruption**

---

## Solves 3 core pain points of MinimaxCode

| Pain Point | Symptom | How this system fixes it |
|------------|---------|--------------------------|
| **Multi-turn drift** | LLM forgets things after 5 turns, fixed bugs recur, no experience accumulation | Each agent maintains `memory.json` (100 entries) + `fix.json` (200 entries), auto-reloads latest 3+3 on wake-up |
| **Workflow reinvented from scratch** | No one knows what standardized flows exist in the project, high onboarding cost for new members | 4 pre-defined workflows (feature/bugfix/review/deploy) + dynamic-to-fixed transformation mechanism |
| **Single agent does everything, nothing well** | One LLM doing API design, testing, and review produces "knows a little of everything" | 4 specialized sub-agents (code-reviewer / api-designer / test-generator / coder), independently tuned, composed on demand |

**Bonus value**: Cross-project portability (whole `.minimax/` directory reusable), CI/CD automation (GitHub + Gitea Actions), cross-platform (Win/Mac/Linux), Docker support, full observability (decision logs + startup metadata + archives).

---

## 5-minute Quick Start

```bash
# 1. Copy to project root
cp -r /path/to/.minimax ./

# 2. Install to mavis
cd .minimax && ./scripts/install.sh

# 3. Launch MinimaxCode and tell it:
"Read .minimax/README.md for workflows, read .minimax/memory/_README.md for the memory system"

# Done
```

Daily usage: write code inside MinimaxCode, **mavis runs sub-agent orchestration + memory in the background**, they share through `.minimax/`.

Emergency bypass:
```bash
MAVIS_PROJECT_BOOTSTRAP_SKIP=1 mavis ...   # skip startup check
MAVIS_MEMORY_ENFORCE_SKIP=1 mavis ...       # skip memory enforcement
```

---

## Project Structure

```
your-project/
├── AGENTS.md / CLAUDE.md / ...  ← MinimaxCode / mavis framework files (untouched)
└── .minimax/                    ← This system (55 files, encapsulates everything)
    ├── README.md                Detailed usage guide
    ├── project.json             Metadata
    ├── config/                  Path abstraction + cross-platform config
    ├── scripts/                 install / uninstall / migrate / export
    ├── hooks/                   MinimaxCode session startup + memory enforcement
    ├── agents/                  4 sub-agents (manifest + prompt)
    ├── workflows/               4 fixed workflows + dual-mode engine
    ├── rules/                   Decision log
    ├── memory/                  Anti-drift memory (5 agents × memory/fix)
    ├── .github/ .gitea/         CI/CD
    ├── Dockerfile + docker-compose
    └── LICENSE + CHANGELOG
```

---

## How to Migrate

```bash
# Cross-machine
./.minimax/scripts/export.sh /tmp/proj.zip
# Copy zip to new machine, unzip + ./install.sh

# Cross-project
cp -r /old/.minimax /new-project/

# Uninstall
./.minimax/scripts/uninstall.sh  # Unregister hook, then delete directory
```

---

## Core Features

### 🚀 Deployment & Migration
- **Plug-and-play** — Copy `.minimax/` whole, install in 30 seconds
- **Relative paths** — All references are relative, not tied to a specific working directory
- **Cross-platform** — Windows / macOS / Linux unified
- **Docker-ready** — Dockerfile + docker-compose, runs inside containers

### 🧠 AI Capabilities
- **Anti-drift** — Memory store (100/200 cap) + 6-entry recomposition (3+3) = never lose context
- **Fixed + Flexible** — Keyword hits use fixed templates, misses use LLM-orchestrated candidates
- **Specialized division of labor** — 4 independent sub-agents: code review / API design / test generation / business coding
- **Persistent registration** — Sub-agent registry persists across sessions

### 🛡️ Reliability
- **Enforced constraints** — SessionStart validates required files + SessionEnd validates memory writes
- **CI/CD** — GitHub + Gitea Actions auto-validate
- **Observable** — Decision logs + metadata injection + archives
- **Rollback-safe** — `uninstall.sh` + `mavis-trash` for clean rollback

---

## Maintenance

- **Author**: TianShu (天枢) <1033085514@qq.com>
- **WeChat**: 1033085514
- **License**: MIT
- **Last Updated**: 2026-06-15
- **Version**: v1.1.0

---

## 💖 Support this framework

If you find my methodology useful, treat me to a cup of tea  :blush: ！

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


**Next steps**:
- 📖 [`.minimax/README.md`](./.minimax/README.md) — Detailed usage guide
- 🛠️ [`.minimax/workflows/README.md`](./.minimax/workflows/README.md) — Dual-mode workflow engine
- 🧠 [`.minimax/memory/_README.md`](./.minimax/memory/_README.md) — Anti-drift memory system
- 🚀 `./.minimax/scripts/install.sh` — Install and run
