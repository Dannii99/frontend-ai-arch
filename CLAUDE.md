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
  core/                # ALWAYS installed — framework-agnostic
    accessibility-a11y/
    frontend-clean-code/          # micro code quality: naming, typing, function size
    frontend-design-principles/   # SOLID + patterns (Facade, Repository, Adapter) — sits above frontend-clean-code
    ui-visual-craft/
    motion-design-system/
    documentation-writer/
  angular/              # only installed if the target project uses Angular
    skills-main/          # vendored: github.com/angular/skills (see BUILD_INFO) — hard reference
    angular-architecture/ # house opinion: folders, state, testing policy
    angular-deploy-safety/
  react/                # only installed if the target uses React WITHOUT Next
    vercel-react-best-practices/  # vendored: Vercel Engineering performance reference
    react-architecture/           # house opinion: folders, server/client state, testing policy
  next/                 # only installed if the target uses Next (wins over react/, see install.sh)
    next-best-practices/  # house-adapted API-by-API reference (user-invocable: false)
    next-conventions/     # house opinion: Server/Client, data patterns, optimization defaults
  domains/              # opt-in only, never auto-loaded by stack detection (--with <name>)
    conversion-ui/
    next-partial-prefetching-adoption/  # vendored from vercel/next.js canary skills
personas/               # roles that use the skills above (see "Personas" section)
install.sh              # the only executable logic in the repo
```

`skills/react/.gitkeep` and similar leftover placeholder files are harmless —
ignore them, don't "clean them up" as a side effect of unrelated work.

## The core-vs-framework skill split

Every skill decision follows one rule (spelled out in `skills/README.md`):
- Universal principle, agnostic of framework → lives in `skills/core/`.
- Framework-specific implementation (depends on that framework's APIs/files/patterns) → lives in `skills/<framework>/`.

`skills/domains/` is different from both: opt-in, situational skills (e.g.
`conversion-ui` applies only to marketing/conversion surfaces; `next-partial-prefetching-adoption`
only when adopting one specific experimental Next.js feature). `install.sh`
never auto-loads a domain skill by stack detection — it must be requested
explicitly via `--with <name>`.

## The reference-vs-architecture pattern (the core structural idea)

Every framework folder (`angular/`, `react/`, `next/`) follows the same
two-layer split, and this is the single most important thing to preserve when
touching skills:

1. **A hard reference skill** — vendored, API-by-API, not house opinion.
   `skills-main` (Angular), `vercel-react-best-practices` (React),
   `next-best-practices` (Next). Don't edit these as if they were your own
   voice; they answer "what exists and how does it work."
2. **A house architecture skill** — `angular-architecture`,
   `react-architecture`, `next-conventions`. These answer "what did we decide,
   given that the reference leaves it open": folder structure
   (`core/`/`shared/`/`features/`), the state-management escalation boundary
   (e.g. Angular: signals-first, store only past a concrete pain trigger;
   React: server state always in TanStack Query/SWR, client state in
   useState/Context, escalate to Zustand/Jotai only past a trigger), and a
   testing policy (what always gets a full test vs. a smoke test vs. e2e).

Sitting above all three framework architecture skills is `frontend-clean-code`
(micro: naming, typing, function size) and `frontend-design-principles`
(SOLID + a curated pattern set — Facade for third-party SDKs, Repository for
data access, Adapter for normalizing external shapes — each gated on a
concrete trigger, never applied by default to avoid over-engineering). Every
framework architecture skill has a "Qué NO va acá" section citing these two
core skills instead of repeating their content — **never duplicate content
across this stack; add a citation instead.**

When adding a new framework's skills, replicate this exact pattern: vendor or
write the hard reference first, then write the architecture skill that cites
it plus `frontend-clean-code`/`frontend-design-principles`, and make sure
nothing in the new architecture skill re-teaches syntax the reference already
owns.

## Vendored subtrees

Vendored = don't rewrite in house voice, don't treat as your own opinion:
- `skills/angular/skills-main/` — github.com/angular/skills (see its `BUILD_INFO` for the imported commit/date).
- `skills/react/vercel-react-best-practices/` — Vercel Engineering, has its own build tooling (`metadata.json`, generated `AGENTS.md`).
- `skills/domains/next-partial-prefetching-adoption/` — vercel/next.js canary skills, noted via `metadata.source` in its frontmatter.

`skills/next/next-best-practices/` is a partial exception: it's a curated,
dispatcher-style API reference (marked `user-invocable: false`) that behaves
like a vendored reference in role, but isn't attributed to an external repo —
treat it the same way (don't fold house opinion into it) unless told
otherwise.

When adapting an external skill for real house use (as opposed to vendoring
it verbatim for reference), rewrite it in this project's own voice —
`skills/README.md` calls this out explicitly: a skill copied as-is doesn't
reflect the architect's judgment and risks license issues in a public repo.

## SKILL.md format

Every skill is a directory containing a `SKILL.md` with YAML frontmatter:

```yaml
---
name: kebab-case-name           # must match the containing folder name
description: >-
  Long-form description covering when to use it (this is what agents match against —
  be specific about triggering situations, not just topic).
compatibility: agnostic        # agnostic | angular | react | next
metadata:
  category: ...
  framework: agnostic | angular | react | next
  scope: domain                # only for skills/domains/, marks it opt-in
  source: ...                  # only on vendored skills, notes upstream origin
---
```

Recurring conventions worth preserving when writing a new skill body:
- State when to use it and when *not* to.
- A house architecture skill states what it does *not* cover and cites the
  skill that does, rather than repeating content (see "reference-vs-architecture
  pattern" above).
- Gate any pattern/abstraction on a concrete trigger ("apply when X, not by
  default") rather than prescribing it unconditionally — this repo actively
  avoids over-engineering guidance.
- Close with "Al terminar, reportá" — a short checklist of what the agent
  should summarize back to the user after applying the skill.

## Personas

`personas/` are roles that consume the skills above, not skill content
themselves — no YAML frontmatter, plain Markdown, always Spanish.

- **`project-owner.md`** — pre-technical product scoping. Produces
  `docs/project-context.md` in the *target* project. Never touches code,
  architecture, or stack choice.
- **`frontend-architect.md`** — orchestrator. Reads `docs/project-context.md`
  if present, detects/decides the stack, decides when a change needs an
  OpenSpec proposal (`openspec/` in the target project) before delegating,
  and cites skills by name rather than re-deciding their content.
- **`frontend-angular-senior.md`** / **`frontend-react-next.md`** —
  execution specialists. Deliberately thin (~40 lines): role, voice, and
  which skills to lean on. Never re-encode in prose what a skill already
  decides — if you're tempted to add a "standards" section to a persona,
  that content belongs in the corresponding architecture skill instead.

There is no Vue persona or `skills/vue/` yet (removed when personas were
cleaned up, since a persona citing skills that don't exist is worse than no
persona) — see the roadmap in `README.md`.

`docs/` (product context, owned by `project-owner`) and `openspec/` (technical
specs, owned by `frontend-architect`) are conventions for the *target*
project a persona works in — this repo itself has neither folder and
shouldn't grow one from unrelated work.

## install.sh

The installer equips a *target* project (elsewhere on disk) with this
ecosystem. Reading it top to bottom explains the whole install flow:

1. Detects package manager (`pnpm-lock.yaml`/`yarn.lock`/`bun.lockb`/default npm) and framework from the target's `package.json`: `@angular/core` → angular; `next` → next; else `react` → react. Next wins over react when both are present (a Next app always depends on `react` too, but `next-conventions` explicitly says not to load `react/` alongside it — see `has_dep` branching in the "Stack" section of the script).
2. Detects which AI agent binary is installed (`claude`, `cursor`, `codex`, `opencode`); prompts if 0 or 2+ found.
3. Checks for the two external "engines" this ecosystem depends on — OpenSpec (spec-driven dev workflow) and Engram (persistent memory via MCP) — and offers (never forces) to install missing ones.
4. Copies `skills/core/` + the detected framework's skill dir (including its vendored reference and any nested `references/` files, since it copies the whole subtree) + `personas/` into the agent's own global skills directory (e.g. `~/.claude/skills`) — never into the target repo.
5. Injects the `AGENTS.md` content into the target project's `AGENTS.md` as an idempotent `<!-- FEA:START -->...<!-- FEA:END -->` block, then runs `openspec init` and `engram setup <agent>`.

Key flags: `--project <path>`, `--agent <name>`, `--yes`, `--dry-run`, `--with <domain1,domain2>`.

The agent-specific logic is confined to two small lookup functions —
`skills_dir_for()` and `engram_agent_arg()` — everything else is
agent-agnostic. When adding support for a new agent, that's where to start.
Personas are copied wholesale regardless of detected framework (an Angular
project still gets `frontend-react-next.md` sitting unused) — this is
intentional simplicity, not a bug; don't "fix" it by filtering personas per
stack without being asked.

## Two-destination rule

- **Global** (agent's own skills dir, Engram memory): travels with the person, never committed to a client's repo.
- **Project** (`AGENTS.md`, `openspec/`, `docs/` inside the target repo): product and technical knowledge specific to that project, committed and travels with that repo.

Don't conflate the two when editing `install.sh` or adding new skills/personas.
