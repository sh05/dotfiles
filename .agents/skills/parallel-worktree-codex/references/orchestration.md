# Codex CLI + Git worktree + optional Herdr

Codex subagents, Codex-managed worktrees, ordinary Git worktrees, and Herdr are distinct mechanisms. Do not treat their status, IDs, or ownership as interchangeable.

## Pick the right mechanism

| Need                                                     | Prefer                                                  | Verify / caveat                                                                                                                                                                  |
| -------------------------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Parallel codebase investigation, tests, or review        | Codex native subagents                                  | Ask for read-only, bounded work. Follow with `/subagents`. A subagent is a thread; don't assume it has a separate checkout.                                                      |
| Continue this chat in an isolated checkout               | Codex TUI `/worktree`                                   | Use in a local Git repository while the primary task is idle. Inspect the selected worktree and branch.                                                                          |
| Run one non-interactive local task in a managed checkout | `codex exec --worktree "..."`                           | Supported for new or forked local exec; do not combine with `resume`, `review`, `--ephemeral`, or `--ignore-user-config`. Inspect `codex exec --help` for the installed release. |
| Several simultaneous write workers                       | Separate Git worktrees + separate Codex CLI processes   | Verify distinct absolute checkout paths, branches, HEADs, and dirty states before each writer starts. Native subagents alone do not establish this isolation.                    |
| Pane/workspace UI for separate Codex processes           | Herdr, only when explicitly requested or already chosen | Require `HERDR_ENV=1` before every Herdr interaction; use local help and verify pane ownership/cwd/process. Herdr isn't necessary for Codex-native subagents.                    |
| Browse chats on a shared Codex server                    | `/agents` or `codex agents`                             | This is a chat command center, not a Git worktree manager or a substitute for `/subagents`.                                                                                      |

Codex's native managed worktree may own its lifecycle. Don't assume a manually created `git worktree add` checkout is registered as a Codex-managed worktree, or that deleting a Git worktree removes/archives a Codex chat. Use the locally documented lifecycle for each resource.

## Safe manual worktree provisioning for parallel writers

Use only if separately launched Codex CLI sessions are part of the requested workflow and native features do not provide the required independent checkouts.

1. Confirm authorization to create local branches/worktrees and launch worker processes. Inspect repo instructions, Git status, current HEAD, and `git worktree list --porcelain`. Do not change existing user worktrees.
2. Select and record one immutable full base SHA. Establish one independent task per checkout; serialize tasks with shared APIs/schema or file ownership conflicts.
3. Choose unique branch and path names. Validate branch names with `git check-ref-format --branch`. Check that path and branch do not already exist. Create only new targets from the fixed base, e.g. `git worktree add -b "$branch" "$path" "$base_sha"` (after checking the installed `git worktree --help`). Never use a forced checkout or prune to make room.
4. In each worktree, independently verify:

   ```bash
   cd "$path"
   pwd -P
   git rev-parse --show-toplevel
   git rev-parse HEAD
   git branch --show-current
   git status --short --branch
   ```

   Compare against the recorded path, intended branch and base. Stop on any mismatch or pre-existing change.

5. Put task instructions in a private directory outside all worktrees and `.git` metadata, with restrictive permissions. Include the exact owned scope and forbid other worktree edits, child delegation, unapproved commit/push/PR/merge, and cleanup.
6. Start one Codex CLI process per worktree using the installed CLI's supported directory-selection option (for example `codex --cd "$path"` only if confirmed by `codex --help`) or set its working directory through the launcher. Keep normal sandbox/approval safeguards. Verify process cwd and ask the worker to confirm branch, HEAD and task-file path before editing.
7. Track observed session/thread identity; do not fabricate IDs. Keep arbitrary process/PID observations distinct from Codex thread IDs. If launch or prompt delivery is uncertain, inspect before retrying.
8. Review all branches and diffs from the coordinator checkout. Worktrees share object database and refs but have separate working directories; concurrent Git operations can still affect branch state, so assign unique branches and do not let workers switch/rebase one another's branches.

A worktree is file isolation, not a security boundary. A process can access paths outside its checkout according to its sandbox and OS permissions.

## Codex subagents

- Use for independent, narrow research, test analysis, and review. Request specific deliverables and prohibit edits when only analysis is needed.
- For delegated implementation, define exact owned files and acceptance checks, and make sure no two agents write the same files. Inspect output diffs and repository state; agent summaries are not verification.
- Codex handles native subagent orchestration and returns results to the parent. `/subagents` is the TUI for inspecting/switching to subagent threads; don't confuse these with independent local CLI processes.
- Native agent threads may be resumed or steered in Codex; don't spawn a replacement merely because the parent cannot see a pane. Check the actual thread first.

## Herdr as an optional Codex launcher

1. If `HERDR_ENV` is not exactly `1`, do not run _any_ Herdr command, including `status` or read-only listing. Use another workflow or ask the user to relaunch the coordinator inside Herdr if its panes are required.
2. If enabled, inspect `herdr status` and actual help for relevant commands. Confirm server/client compatibility and supported pane/worktree operations; don't assume Herdr has a Codex agent kind, Codex prompt API, or Goose behavior.
3. Provision/verify an independent worktree first. Create or reuse a pane only with explicit permission and confirmed ownership. Check pane ID, cwd, foreground process, and screen before starting a separate `codex` process.
4. Avoid passing task bodies as shell code. Send only a simple instruction to read the private task file after confirming that the target pane is an expected Codex input prompt. Never auto-accept trust, sandbox, permission, or authentication dialogs.
5. Codex may itself have `/worktree` and subagent actions. Do not send commands to a pane running a different session, and do not launch duplicate workers because a state hook says idle or because a completion screen appeared.
6. Codex status, Herdr status, process status, and Git changes are independent evidence. Verify the actual checkout and changes before reporting completion.

## Verification and cleanup

- The parent checks `git status --short --branch`, `git diff --stat`, `git diff`, and `git ls-files --others --exclude-standard` in every worker checkout. Run exact repository tests and distinguish failed, skipped, and not-run checks.
- A completed turn, idle thread, process exit, or clean status alone does not prove task success: a task may have produced no changes or failed requirements. Compare results to acceptance criteria.
- Reconcile the registry with actual running processes/threads and `git worktree list --porcelain` before restarting or cleaning up.
- Cleanup is a separate permission. Never force-remove a dirty worktree, delete a branch/session, or kill a process with uncertain ownership. Preserve all changed and untracked data and ask before destructive action.
