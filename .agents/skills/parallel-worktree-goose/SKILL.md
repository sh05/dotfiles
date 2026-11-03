---
name: parallel-worktree-goose
description: Create and coordinate isolated Git worktrees in Herdr, with one Goose session per worktree workspace. Use when the user asks to parallelize substantial development, create worktree-based tasks, or start Goose sessions in Herdr workspaces/tabs.
---

# Parallel development with Herdr worktrees and Goose

Use this workflow to give each parallel coding task its own Git worktree, Herdr workspace, and Goose session. Each worktree is a separate checkout and branch; never have two agents edit the same checkout concurrently.

## Safety and preflight

1. Confirm Herdr access before controlling it:
   ```bash
   test "${HERDR_ENV:-}" = 1
   ```
   If this is not a Herdr-managed pane, tell the user that you cannot operate their Herdr session from here. Do not inspect or control it.
2. Read the installed CLI's current syntax and discover the caller's live workspace/pane IDs:
   ```bash
   herdr worktree
   herdr workspace list
   herdr pane current --current
   ```
   Use the installed CLI as authority; do not guess IDs or assume old examples are current.
3. Identify the source checkout with `git rev-parse --show-toplevel`, inspect `git status --short`, and check existing linked worktrees with `herdr worktree list --cwd <source-checkout>`.
4. Do not silently discard, move, or copy uncommitted changes into new worktrees. If the source checkout is dirty and the task depends on those changes, explain that new worktrees start from a commit and ask how to handle the changes. Preserve unrelated user changes.
5. Before creating branches, ensure task boundaries are independent and branch names are unique. Ask the user to clarify overlapping file ownership or conflicting tasks before launching them.

## Create one isolated Goose workspace per task

For each explicitly requested task, create a new worktree from the chosen base (normally the source checkout's current branch/HEAD):

```bash
herdr worktree create \
  --cwd <source-checkout> \
  --branch <unique-branch-name> \
  --base <base-ref> \
  --label <short-task-label> \
  --no-focus
```

- Use a concise, unique branch name and a label that identifies the task.
- `herdr worktree create` is the worktree-aware operation: it creates/opens the linked checkout and its Herdr workspace. Do not separately make a workspace for the same worktree.
- Read the JSON result; do not invent IDs or paths. Verify the new entry using `herdr worktree list --cwd <source-checkout>` and `herdr workspace list`. Record the returned worktree path, workspace ID, tab ID, and root pane ID for the next steps.
- If a branch/worktree already exists, inspect it and use `herdr worktree open` for that existing checkout rather than trying to create a duplicate. Never remove an existing worktree as a shortcut.

Start a Goose CLI session in the worktree's root pane:

```bash
herdr pane run <returned-root-pane-id> goose session
```

Use the exact returned root pane ID and verify that the pane is running Goose before sending work. The repository's existing Goose lifecycle integration reports agent state to Herdr. Keep `--no-focus` unless the user asked to focus the new workspace.

If the user wants several separate conversations in one worktree, create additional tabs explicitly in that worktree workspace and set their cwd to that worktree path:

```bash
herdr tab create --workspace <workspace-id> --cwd <worktree-path> --label <tab-label> --no-focus
```

Then run `goose session` in each returned root pane. For independent parallel coding tasks, prefer separate worktrees/workspaces over multiple agents sharing one checkout.

## Delegate and monitor

- Give each Goose session a narrow, non-overlapping task. Include the worktree path, expected outcome, relevant tests, and a request to avoid editing outside its assigned scope.
- Use Herdr's agent interface when the Goose pane is detected as an agent. Discover names/IDs from live output; do not guess. For example:
  ```bash
  herdr agent list
  herdr agent prompt <agent-name-or-pane-id> "<task>" --wait --timeout 600000
  ```
  If the Goose session is not detected as an agent yet, inspect the pane and wait for startup; do not blindly resubmit a prompt after a timeout.
- Keep the user's focus unchanged unless asked. Use current IDs from command output because panes/workspaces are live session identifiers.
- Before integration, inspect each worktree's `git status`, branch, and diff; run the relevant tests. Report branch and worktree path for each task and any unfinished work or conflicts.
- Do not merge, rebase, commit, push, or remove worktrees unless the user asks. Integrate completed branches only with explicit user direction. Never close or remove workspaces/worktrees you did not create.

## Cleanup after integration

After the user confirms a PR/branch has been merged (or explicitly asks to discard a completed task), clean up the task's Herdr resources rather than leaving a stale worktree workspace, tab, and checkout behind. A merge alone is not sufficient evidence if the user has not asked for cleanup; when the user says the task is finished and requests cleanup behavior, proceed for the identified task.

Before removing anything:

1. Identify the exact task branch, worktree path, workspace ID, tab IDs, and pane IDs from live Herdr/Git output. Do not infer IDs from old output.
2. Verify the PR is merged or the user explicitly authorized discarding the task. Check `git status --short` in the worktree and inspect uncommitted/untracked changes. If anything remains, preserve it and ask the user what to do; never use `--force` to bypass this.
3. Ensure the branch's work has been integrated (or the user explicitly chose to discard it). Do not delete the Git branch unless separately requested.
4. Check the installed CLI help for `herdr worktree remove` and use the worktree-aware removal command for the exact workspace:
   ```bash
   herdr worktree remove --workspace <workspace-id>
   ```
   This should remove the linked checkout and its associated Herdr workspace/tab. Read the result, then verify with `herdr worktree list --cwd <source-checkout>` and `herdr workspace list` that the task worktree and workspace are gone.
5. If a task created additional tabs that are not removed with the worktree workspace, list them and close only those tabs after confirming their panes contain no needed work. Do not close unrelated tabs/workspaces. If the CLI reports that a separate close is required, use the current IDs from fresh list output.

Do not remove the source checkout, unrelated worktrees, branches, sessions, or user-created tabs. If cleanup is not requested or the state is ambiguous, report the exact resources and ask before destructive cleanup.

## Report back

Summarize the task-to-branch-to-worktree-to-workspace mapping, whether each Goose session started, and the current state. Clearly distinguish a created workspace from an agent that has actually started working. Mention any dirty source checkout, test failures, or integration decisions needed.
