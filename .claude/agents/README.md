# Project Subagents

Specialist helpers that the JMVG fleet's six primary agents can spawn for narrow tasks. Defined as Claude Code project subagents (YAML frontmatter + prompt body) and auto-discovered by the Claude Code harness when the cwd is anywhere inside this repo.

## Helpers

| Agent | Model | Use |
|---|---|---|
| `code-reviewer` | opus | AI + static-analysis code review. Spawn from Manager post-PR or BE/FE pre-merge. |
| `architect-review` | opus | C4/ADR-grade architectural sweep for cross-repo or cross-app changes. |
| `security-auditor` | opus | OWASP / SAST pass before auth or Jarvis-routing changes. |
| `prompt-engineer` | opus | "Always show full prompt" discipline + 7-step methodology. Adopt structure into HELIX. |
| `context-manager` | opus | Multi-agent context orchestration, memory, RAG patterns. |
| `debugger` | sonnet | 5-step root-cause + reproduction + prevention loop. |

## Attribution

These six helpers are vendored from [`wshobson/agents`](https://github.com/wshobson/agents) under the MIT License. Original copyright © 2024 Seth Hobson. See `LICENSE-wshobson` in this directory for the full license text.

To pull updates from upstream:

```bash
BASE=https://raw.githubusercontent.com/wshobson/agents/main/plugins
curl -fsSL -o code-reviewer.md     $BASE/comprehensive-review/agents/code-reviewer.md
curl -fsSL -o architect-review.md  $BASE/comprehensive-review/agents/architect-review.md
curl -fsSL -o security-auditor.md  $BASE/security-compliance/agents/security-auditor.md
curl -fsSL -o prompt-engineer.md   $BASE/llm-application-dev/agents/prompt-engineer.md
curl -fsSL -o context-manager.md   $BASE/context-management/agents/context-manager.md
curl -fsSL -o debugger.md          $BASE/debugging-toolkit/agents/debugger.md
```

## Mirroring into the other repos

Cloud routines run from `/home/user/<repo>/`. To make helpers available in `ro-control`, `ro-tools`, `ro-control-ios`, `ro-tools-ios`, or `jmvg-ios-shared`:

```bash
# From the target repo root:
mkdir -p .claude/agents
cp ../jmvg-ops/.claude/agents/*.md .claude/agents/
cp ../jmvg-ops/.claude/agents/LICENSE-wshobson .claude/agents/
```

Or set up a single user-level install at `~/.claude/agents/` for fleet-wide availability without per-repo duplication.

## Local override

Don't edit vendored files in place — upstream updates will overwrite. Add JMVG-specific overrides as `<agent-name>-jmvg.md` in this directory instead.
