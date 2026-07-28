# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is **not** an application — it's "Frontend AI Ecosystem" (Wordflow), a
portable layer of order, memory, skills, and working method that gets
installed *on top of* other projects and other AI agents (Claude Code, Cursor,
Codex, OpenCode). There is no build, lint, or test command: the deliverable is
Markdown (`SKILL.md` files, agent roles/subagents, custom commands, `AGENTS.md`)
plus one bash installer.

Read `README.md` and `AGENTS.md` at the repo root first — they are the
canonical explanation of the project's purpose and are written in Spanish
(the working language of this repo; keep new skill/agent content in Spanish
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
    playwright-visual-review/           # live MCP review + persisted e2e generation guidance
commands/
  fea/                  # Claude Code custom slash-commands, namespace /fea:*
                        # (plan, execute, test, verify, review, archive, fix, explore, audit)
                        # — see "agents/" section
agents/                 # roles + subagents that consume the skills above (see "agents/" section)
  project-owner.md              # conversational role: pre-technical product scoping
  frontend-architect.md         # conversational role: orchestrator
  frontend-angular-senior.md    # conversational role: Angular execution specialist
  frontend-react-next.md        # conversational role: React/Next execution specialist
  code-writer.md                # mechanical subagent: used by commands/fea/execute.md, fix.md
  code-auditor.md               # mechanical subagent: used by execute/fix/verify/audit
  test-generator.md             # mechanical subagent: used by commands/fea/test.md
  visual-reviewer.md            # mechanical subagent: used by commands/fea/review.md (Playwright MCP)
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
only when adopting one specific experimental Next.js feature; `playwright-visual-review`
only when a change has UI surface worth reviewing live or a golden path
worth locking in as e2e). `install.sh` never auto-loads a domain skill by
stack detection — it must be requested explicitly via `--with <name>`.

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

This split is for *framework* folders specifically, not every multi-part
skill. `skills/domains/playwright-visual-review/` deliberately stays a
single cohesive `SKILL.md` — Playwright's surface (a handful of MCP browser
tools + one test runner) is far more contained than an entire framework
ecosystem, so splitting it into a vendored reference plus a house-opinion
layer would just be ceremony. Don't force the two-layer pattern onto a skill
this size.

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

## agents/

`agents/` are roles and subagents that consume the skills above, not skill
content themselves — YAML frontmatter (`name` + `description`, same shape as
a Claude Code subagent definition), body in plain Markdown, always Spanish.
It holds two kinds of file, deliberately merged into one folder rather than
split into two components:

**Conversational roles** — thick (frontend-architect is ~150 lines,
angular-senior/react-next ~40), meant to be adopted for a whole
conversation/session, either explicitly invoked as a Claude Code subagent or
just read and embodied by any agent when a human says "act as X":

- **`project-owner.md`** — pre-technical product scoping. Produces
  `docs/project-context.md` in the *target* project. Never touches code,
  architecture, or stack choice.
- **`frontend-architect.md`** — orchestrator. Reads `docs/project-context.md`
  if present, detects/decides the stack, decides when a change needs an
  OpenSpec proposal before delegating (mechanized via `commands/fea/*.md` —
  see below), and cites skills by name rather than re-deciding their content.
- **`frontend-angular-senior.md`** / **`frontend-react-next.md`** —
  execution specialists. Deliberately thin: role, voice, and which skills to
  lean on. Never re-encode in prose what a skill already decides — if you're
  tempted to add a "standards" section to one of these, that content belongs
  in the corresponding architecture skill instead.

**Mechanical subagents** — narrow, one job, invoked by `commands/fea/*.md`
per task rather than directly by a person: `code-writer` (implements),
`code-auditor` (reviews against `frontend-clean-code`/
`frontend-design-principles`/`accessibility-a11y`/the detected framework's
architecture skill, runs lint, returns a verdict), `test-generator` (writes
tests after implementation, from the spec's WHEN/THEN + the real code's
signatures — including persisted Playwright `.spec.ts` for scenarios the
architecture skill's testing policy marks "e2e"), `visual-reviewer` (drives
Playwright MCP against the running app for a live review — accessibility
tree, screenshots, console — never writes files; see `commands/fea/review.md`
and `skills/domains/playwright-visual-review/`).

There is no Vue role or `skills/vue/` yet (removed when personas were
cleaned up, since a role citing skills that don't exist is worse than no
role) — see the roadmap in `README.md`.

`docs/` (product context, owned by `project-owner`) and `openspec/` (technical
specs, owned by `frontend-architect`) are conventions for the *target*
project an agent works in — this repo itself has neither folder and
shouldn't grow one from unrelated work.

### commands/fea/\* — mechanizing the OpenSpec flow

`frontend-architect.md` used to describe the OpenSpec propose/apply/archive
flow in prose. `commands/fea/*.md` now mechanizes it as Claude Code custom
slash-commands (namespace `/fea:*`, one per lifecycle step — `plan`,
`execute`, `test`, `verify`, `review`, `archive`, `fix`, `explore`, `audit`),
and `frontend-architect.md` cites them instead of re-describing the steps.
Same "cite, don't reimplement" rule that already governs skills applies
here. `execute.md`/`fix.md` are what actually delegates to the mechanical
subagents above (`code-writer` → `code-auditor`, `test-generator` via
`test.md`, `visual-reviewer` via `review.md`).

`review.md` fills a gap `verify.md` states explicitly: verify is "static
only — never calls a deployed endpoint or runs curls." `review.md` is the
live counterpart — it drives a real browser via Playwright MCP against the
running app. It's suggested (not required) before `archive.md`, same as
`verify.md` — see `archive.md`'s non-blocking suggestion step.

**Important caveat:** unlike skills (Agent Skills, an open standard this repo
is built on — see `README.md`) and unlike `agents/` (which has a guaranteed
install destination for all 4 supported agents, see below), custom
slash-commands are a Claude Code-native mechanism with no equivalent on
Cursor/Codex/OpenCode. `install.sh` treats `commands/` as a best-effort,
non-blocking install (see `commands_dir_for()`) — if the detected agent has
no known destination, it warns and skips instead of failing. The content
still works as plain reference material for any agent that reads it, even
without native slash-command support — it just won't be invoked via
`/fea:plan` syntax.

## install.sh

The installer equips a *target* project (elsewhere on disk) with this
ecosystem. Reading it top to bottom explains the whole install flow:

1. Detects package manager (`pnpm-lock.yaml`/`yarn.lock`/`bun.lockb`/default npm) and framework from the target's `package.json`: `@angular/core` → angular; `next` → next; else `react` → react. Next wins over react when both are present (a Next app always depends on `react` too, but `next-conventions` explicitly says not to load `react/` alongside it — see `has_dep` branching in the "Stack" section of the script).
2. Detects which AI agent binary is installed (`claude`, `cursor`, `codex`, `opencode`); prompts if 0 or 2+ found.
3. Checks for the external "engines" this ecosystem depends on — OpenSpec (spec-driven dev workflow) and Engram (persistent memory via MCP) — and offers (never forces) to install missing ones.
4. Copies `skills/core/` + the detected framework's skill dir (including its vendored reference and any nested `references/` files, since it copies the whole subtree) into the agent's own global skills directory (e.g. `~/.claude/skills`) — never into the target repo. Copies `agents/` (all 8 files — conversational roles + mechanical subagents, see "agents/" above) into the agent's own subagents directory (e.g. `~/.claude/agents`) via `copy_optional_dir()`, with a guaranteed destination for all 4 supported agents. Copies `commands/` into the agent's own commands directory (e.g. `~/.claude/commands`) the same way, but non-blocking: if `commands_dir_for()` returns empty for the detected agent (no known native support), it warns and moves on instead of failing.
5. Injects the `AGENTS.md` content into the target project's `AGENTS.md` as an idempotent `<!-- FEA:START -->...<!-- FEA:END -->` block, then runs `openspec init --tools "$AGENT"` (first run) or `openspec update` (if `openspec/` already exists — avoids re-running `init --force` over real specs), `engram setup <agent>`, and `ensure_playwright_mcp` — a third engine, wired the same way as Engram (per-agent MCP registration, not a global binary check). For `claude` it runs `claude mcp add playwright -- npx @playwright/mcp@latest` (idempotent — checks `claude mcp list` first); for `cursor`/`codex` it prints the manual config snippet (`.cursor/mcp.json` / `~/.codex/config.toml`) since auto-writing those risks corrupting an existing file; for `opencode` it prints a pointer and explicitly flags the exact config format as unconfirmed for that agent — don't treat that hedge as a TODO to silently "fix" without verifying against a real OpenCode install first. OpenSpec's tool IDs are identical to this script's own `$AGENT` values, so no mapping function is needed there (unlike `engram_agent_arg()`).

Key flags: `--project <path>`, `--agent <name>`, `--yes`, `--dry-run`, `--with <domain1,domain2>`.

The agent-specific logic is mostly confined to four small lookup functions —
`skills_dir_for()`, `agents_dir_for()`, `commands_dir_for()`, and
`engram_agent_arg()` — everything else is agent-agnostic. When adding support
for a new agent, that's where to start. `skills_dir_for()` and
`agents_dir_for()` both guarantee a real destination for all 4 supported
agents (`skills_dir_for()` is the one with `exit 1` if the agent itself is
unsupported); `commands_dir_for()` is the only genuinely best-effort one (see
"commands/fea/\*" above). `ensure_playwright_mcp()` is the one exception to
"lookup function returns a path" — it does its own per-agent `case` because
registering an MCP server is an action (a command to run, or a config
snippet to print), not a directory to resolve; it still lives right next to
the other adapters and should be extended the same way if a 5th agent is
added. Agents are copied wholesale regardless of detected framework (an
Angular project still gets `frontend-react-next.md` sitting unused) — this
is intentional simplicity, not a bug; don't "fix" it by filtering agents per
stack without being asked.

## Two-destination rule

- **Global** (agent's own skills dir, agents dir, commands dir, Engram memory): travels with the person, never committed to a client's repo. `agents/` follows this bucket with the same guaranteed-destination as `skills/`; `commands/` follows it too but best-effort (see "agents/" above).
- **Project** (`AGENTS.md`, `openspec/`, `docs/` inside the target repo): product and technical knowledge specific to that project, committed and travels with that repo.

Don't conflate the two when editing `install.sh` or adding new skills/agents/commands.

**Deliberate exception:** files that `openspec init` generates inside the
*target* repo (`.claude/skills/openspec-*/SKILL.md`, `.claude/commands/opsx/*.md`,
and the `.cursor/`/`.codex/`/`.opencode/` equivalents) are project-local by
OpenSpec's own design, not ours — they're committed to the client's repo
alongside `openspec/`. This is not an inconsistency with the rule above: it's
OpenSpec doing its own per-agent wiring (see the `openspec init` call in
install.sh's "Orquestar los motores" step). Don't "fix" this by trying to
move OpenSpec's generated skills/commands into the agent's global skills dir
— that's not how the tool is designed to work.
