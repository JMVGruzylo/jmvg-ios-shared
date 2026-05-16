# Claude Code project config

This directory is consumed by the Claude Code harness when a session's cwd is anywhere inside `jmvg-ops`. It supplies project subagents, hooks, and settings for the JMVG fleet.

## Layout

```
.claude/
  agents/                  Project subagents (helpers any fleet member can spawn)
    code-reviewer.md       AI + static-analysis review (Opus)
    architect-review.md    C4/ADR-grade architectural sweep (Opus)
    security-auditor.md    OWASP / SAST pass (Opus)
    prompt-engineer.md     Prompt-engineering discipline (Opus)
    context-manager.md     Multi-agent context / RAG orchestration (Opus)
    debugger.md            Root-cause + fix + verify loop (Sonnet)
    LICENSE-wshobson       MIT license for the vendored helpers
    README.md              Helper inventory + upstream-sync + mirror instructions
  hooks/
    post-edit-typescript.sh    Advisory hint on .ts/.tsx edits — non-blocking
    stop-session-reminder.sh   Closing-checklist reminder (queue tick + memory)
  settings.json            Hook wiring (PostToolUse + Stop)
  README.md                This file
```

## Hooks

Two minimal, non-blocking hooks today:

| Event | Hook | What it does |
|---|---|---|
| `PostToolUse` (Edit / Write) | `post-edit-typescript.sh` | If the edited file is `.ts` / `.tsx`, emits a build-before-commit hint to stderr. Non-blocking; advisory only. |
| `Stop` | `stop-session-reminder.sh` | Emits the closing checklist (tick queue, append memory, commit + push). Non-blocking. |

Neither hook blocks tool use or session end. They close the "agent forgets to update memory" gap that the slim-boot-card pattern alone doesn't catch.

When we want stricter gates (e.g., a real `tsc --noEmit` pre-commit gate or a Stop blocker until memory is appended), HELIX or BackEndAgent can replace these with cached / state-aware versions modeled after `bartolli/claude-code-typescript-hooks` and `disler/claude-code-hooks-mastery`.

## Mirroring into other repos

The Claude Code harness reads `.claude/` from the session's cwd. To get the same agents + hooks active when working in `ro-control`, `ro-tools`, etc.:

```bash
# From the target repo root:
mkdir -p .claude
cp -r ../jmvg-ops/.claude/agents .claude/
cp -r ../jmvg-ops/.claude/hooks .claude/
cp ../jmvg-ops/.claude/settings.json .claude/
```

Or set up `~/.claude/` (user-level) once, and all repos pick up the same config.

## Adding new subagents

- Vendored from upstream (e.g., another wshobson agent): drop in `agents/`, update `agents/README.md` with attribution.
- JMVG-specific: name as `<agent-name>-jmvg.md` to mark it as a local override.
- Custom helpers HELIX or BackEndAgent define: same — local files in `agents/`.

## Adding new hooks

- Drop the script in `hooks/`, make it executable, wire it in `settings.json`.
- Test it locally first; cloud routines have a different security posture and may surface different env vars.
- Hooks emit to stderr to keep tool output streams clean.
- Keep them fast (< 100ms typical) so they don't lag the session.
