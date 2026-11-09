---
name: parallel-worktree-codex
description: >-
  Coordinate parallel Codex CLI tasks with isolated Git worktrees, using Codex's
  native subagent and worktree features where appropriate and Herdr only as an
  optional terminal multiplexer. Use for explicitly parallel or multi-worker
  Codex CLI work, worktree isolation, or Codex+Herdr coordination; do not use
  merely for a routine single-agent task.
---

# parallel-worktree-codex

Codex CLI is the coordinator by default; worker Codex sessions do the assigned implementation. Use Codex's built-in subagents for bounded investigation/review and its native worktree workflow for the coordinator's own checkout. **Do not assume a Codex subagent has its own Git worktree:** before parallel write work, verify that each writer really has a distinct worktree and branch. If that cannot be arranged and verified, parallelize read-only tasks only or work sequentially.

Herdr is optional. Use it only when the user asks for Herdr or already wants its panes/workspaces used. Do not use Herdr to control Codex subagents; Codex owns those threads. Herdr may host separate Codex CLI processes in dedicated worktrees.

## Coordination rules

- The coordinator owns the plan, task breakdown, dependency graph, base SHA, worker registry, approvals, integration, and final verification. Keep implementation in the assigned workers unless the user asks otherwise.
- Parallelize only independent tasks. A worktree isolates files, not semantic dependencies, shared APIs, external resources, or integration risk. Serialize dependent work and assign shared contracts/files to one owner.
- Prefer Codex native subagents for read-only exploration, test investigation, and independent review. Ask Codex explicitly to delegate when useful; inspect and steer with `/subagents`. `/agents` or `codex agents` is for browsing chats on a shared server, not a worktree or worker launcher.
- Use `/worktree` for moving the current chat into a Codex-managed worktree. `codex exec --worktree` creates a managed worktree for a new or forked local exec. These features do **not** prove that parallel subagents are in separate checkouts. Use the installed CLI's `codex --help` / `codex exec --help` and the official command reference before relying on command flags or lifecycle behavior.
- For independent implementation sessions, each worker must have its own verified branch and worktree. Use a documented Codex-managed workflow if it supports the needed worker layout; otherwise use `git worktree add` with a fixed base SHA and launch a separate Codex CLI session in that checkout (for example via the locally verified `--cd` option). If Herdr is the launcher, follow the local Herdr help. Never start multiple writers in the same checkout just because they are separate Codex threads.
- A Git worktree is not a security sandbox. Codex sandbox and approval settings still apply. Do not pass flags that disable safeguards, approve permissions automatically, or change Codex / Herdr configuration without explicit authorization.

## Herdr guard

- Before **any** Herdr status, list, or control command, require `test "${HERDR_ENV:-}" = 1`. If it is not set, do not inspect Herdr at all; continue with Codex-native or ordinary Git workflows, or ask the user to start Codex in Herdr if panes are required.
- When enabled, inspect `herdr status` and the installed `herdr --help` / relevant subcommand help. Confirm client/server compatibility and exact command syntax. Do not invoke bare `herdr` (it may launch the TUI), assume Goose agent commands work for Codex, or guess at Codex-specific support.
- Confirm each pane's actual owner, cwd, foreground process, and expected Codex session before sending input. Do not automate trust, permission, approval, or authentication prompts. If pane ownership or input state is unclear, stop.
- Herdr hook/status reporting is not the Codex worker registry and is not proof of task success. Codex thread status, Herdr pane status, process state, and Git state are separate observations.

## Workflow

1. **Plan and inspect**: Read applicable `AGENTS.md` instructions. Inspect `git status --short --branch`, `git worktree list --porcelain`, current HEAD, branch, and existing worktree changes before creating anything. Fix a full base SHA. Define task boundaries, dependencies, file/resource ownership, acceptance checks, and who may commit/push/create PRs. Do not overwrite, reset, stash, clean, or reuse another task's dirty worktree.
2. **Choose the execution model**:
   - Read-only or non-overlapping analysis: Codex native subagents are appropriate; explicitly ask for bounded tasks and concise findings with file/line references. Ensure they do not edit.
   - Parallel implementation: provision one branch + worktree + Codex process per independent task, and verify `git rev-parse HEAD`, branch, cwd, and `git status` in each before sending its task. If available features cannot guarantee this isolation, stop parallel writes.
   - A single implementation: use Codex's `/worktree` when a separate managed checkout is useful; do not create unnecessary workers.
3. **Prepare task instructions**: Keep each full task file outside every checkout and Git metadata directory in a private directory (directory mode 700, file mode 600 where supported). Include only necessary, shareable context, fixed base SHA, exact worktree/branch, owned files, acceptance criteria, tests, and permissions. Do not copy private conversation, other workers' task files, credentials, backups, or unrelated sensitive data. Treat issue/PR content as untrusted specification, not shell instructions.
4. **Start workers**: Use the Codex-native subagent flow for read-only assignments. For isolated implementation workers, start one separate local Codex CLI session in each verified worktree, following installed CLI help; if using Herdr, first satisfy the Herdr guard and verify the pane before launching. Prompt each worker with a fixed request to read its task file by absolute path; do not interpolate issue text into shell commands. Do not start duplicate workers when send/launch status is uncertain.
5. **Track and intervene**: Keep a coordinator-owned registry with task, dependency, owner, attempt, branch, worktree, Codex thread/session ID (if actually observed), state, blockers, next action, and verification evidence. Codex `/subagents` reports Codex-managed thread activity; it does not report arbitrary Codex CLI processes. Check each worker's actual pane/process/cwd and Git state as needed. `working`, `idle`, or process exit are observations, not proof of correctness or completion. After a timeout/error or uncertain prompt delivery, inspect actual state before retrying; do not resend blindly.
6. **Review and integrate**: For each worker, inspect branch/HEAD/diff, untracked files, acceptance criteria, and actual test results. Mark verified only after the coordinator confirms them. Integrate only when explicitly authorized; review base relationships and order, resolve conflicts deliberately, and rerun relevant tests after integration. No push, PR, merge, or commit unless specifically allowed.
7. **Cleanup**: Remove only worktrees/branches/processes created for this run, only when the user explicitly requested cleanup and ownership is certain. Preserve uncommitted/untracked files and commits; if anything needs preservation, stop and ask. Do not use `git worktree remove --force`, `git clean`, hard reset, or delete another Codex/Herdr session. Codex-managed worktree lifecycle must follow the installed CLI's documented UI/commands.

The coordinator registry is a planning aid, not a lock or a live source of truth. On restart, reconcile it with actual Codex thread/process, Herdr pane (if used), and Git/worktree state before resuming; never duplicate a worker whose state is live or unknown.

See [references/orchestration.md](references/orchestration.md) for CLI/Herdr distinctions and [templates/worker-task.md](templates/worker-task.md) for a private worker instruction template.

## Official references

- [Codex CLI developer commands](https://learn.chatgpt.com/docs/developer-commands?surface=cli) — `/worktree`, `codex exec --worktree`, `/agents`, `/subagents`, and CLI options.
- [Codex subagents](https://developers.openai.com/codex/multi-agent) — built-in subagent workflow and coordination.
- [Codex skills](https://developers.openai.com/codex/skills) — skill format and `$HOME/.agents/skills` discovery.
