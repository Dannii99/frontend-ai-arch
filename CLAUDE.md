# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is **not** an application — it's "Frontend AI Ecosystem" (Wordflow), a
portable layer of order, memory, skills, and working method that gets
installed *on top of* other projects and other AI agents (Claude Code, Cursor,
Codex, OpenCode). There is no build, lint, or test command: the deliverable is
Markdown (`SKILL.md` files, personas, `AGENTS.md`) plus one bash installer.

Read `README.md` and `AGENTS.md` at the repo root first — they are the
canonical explanation of the project's purpose and are written in Spanish
(the working language of this repo; keep new skill/persona content in Spanish
unless a file is a vendored upstream import).

## Repo structure

```
AGENTS.md              # canonical cross-agent standards, injected into target projects by install.sh
skills/
  README.md            # explains the core vs framework taxonomy
  core/                # ALWAYS installed — framework-agnostic principles (a11y, clean code, docs, visual craft)
  angular/, react/, next/, ...  # framework-specific "how", only installed if the target project uses it
  domains/              # opt-in, situational skills (e.g. conversion-ui) — never auto-installed by stack detection
personas/               # role prompts (e.g. frontend-architect.md)
install.sh              # the only executable logic in the repo
```

## The core-vs-framework skill split

Every skill decision follows one rule (spelled out in `skills/README.md`):
- Universal principle, agnostic of framework → lives in `skills/core/`.
- Framework-specific implementation (depends on that framework's APIs/files/patterns) → lives in `skills/<framework>/`.

Example: accessibility as a *concept* is `core/accessibility-a11y`; the Angular
CDK focus-trap pattern would be `angular/`. When adding a skill, decide which
side of that line it's on before placing the file.

`skills/domains/` is different from both: opt-in, situational skills (e.g.
`conversion-ui` applies only to marketing/conversion surfaces, never to
internal dashboards). `install.sh` never auto-loads a domain skill by stack
detection — it must be requested explicitly via `--with <name>`.

## Vendored subtrees

`skills/angular/skills-main/` is a **vendored copy of github.com/angular/skills**
(see `BUILD_INFO` for the imported commit/date), not original content. Don't
edit it as if it were house style. `skills/next/referens/` is similarly a
reference/vendored knowledge base of Next.js docs rather than an authored
skill.

When adapting an external skill for real use in this repo (as opposed to
vendoring it verbatim for reference), rewrite it in this project's own voice —
`skills/README.md` calls this out explicitly: a skill copied as-is doesn't
reflect the architect's judgment and risks license issues in a public repo.

## SKILL.md format

Every skill is a directory containing a `SKILL.md` with YAML frontmatter:

```yaml
---
name: kebab-case-name
description: >-
  Long-form description covering when to use it (this is what agents match against —
  be specific about triggering situations, not just topic).
compatibility: agnostic        # optional
metadata:
  category: ...
  framework: agnostic | angular | react | ...
  scope: domain                # only for skills/domains/, marks it opt-in
---
```

Recurring conventions worth preserving when writing a new skill body:
- State when to use it and when *not* to (see `conversion-ui`'s explicit "no
  la uses en apps internas" carve-out).
- Prefer additive, minimal-risk fixes over broad rewrites (a11y and deploy-safety
  skills both state this as their guiding principle).
- Some skills close with a traffic-light verdict (rojo/amarillo/verde) —
  follow that pattern for audit-style skills like `accessibility-a11y`.

## install.sh

The installer equips a *target* project (elsewhere on disk) with this
ecosystem. Reading it top to bottom explains the whole install flow:

1. Detects package manager (`pnpm-lock.yaml`/`yarn.lock`/`bun.lockb`/default npm) and framework (`@angular/core`, `react` in the target's `package.json`).
2. Detects which AI agent binary is installed (`claude`, `cursor`, `codex`, `opencode`); prompts if 0 or 2+ found.
3. Checks for the two external "engines" this ecosystem depends on — OpenSpec (spec-driven dev workflow) and Engram (persistent memory via MCP) — and offers (never forces) to install missing ones.
4. Copies `skills/core/` + the detected framework's skill dir + `personas/` into the agent's own global skills directory (e.g. `~/.claude/skills`) — never into the target repo.
5. Injects the `AGENTS.md` content into the target project's `AGENTS.md` as an idempotent `<!-- FEA:START -->...<!-- FEA:END -->` block, then runs `openspec init` and `engram setup <agent>`.

Key flags: `--project <path>`, `--agent <name>`, `--yes`, `--dry-run`, `--with <domain1,domain2>`.

The agent-specific logic is confined to two small lookup functions —
`skills_dir_for()` and `engram_agent_arg()` — everything else is
agent-agnostic. When adding support for a new agent, that's where to start.

## Two-destination rule

- **Global** (agent's own skills dir, Engram memory): travels with the person, never committed to a client's repo.
- **Project** (`AGENTS.md`, `openspec/` inside the target repo): product knowledge, committed and travels with that repo.

Don't conflate the two when editing `install.sh` or adding new skills/personas.
