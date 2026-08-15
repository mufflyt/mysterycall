# Coding-agent instructions: mysterycall

These guards exist because a prior session fell into a loop: `R/county_covariates.R`
was rewritten repeatedly and `devtools::document()` was relaunched over and over
without the task list advancing. The rules below are mandatory for any coding agent
working in this repository.

## GUARDS: DO NOT VIOLATE

1. Work on one task at a time.
   - Finish, test, and summarize the current task before starting another.
   - Do not modify files for later checklist items during the current task.

2. Never rewrite the same file repeatedly without new evidence.
   - Read the existing file before editing it.
   - After writing, inspect the diff immediately.
   - Do not rewrite that file again unless a test produces a new, specific
     failure that requires another change.
   - Maximum: two edit attempts per file before stopping and reporting the
     unresolved problem.

3. Prevent command loops.
   - Do not rerun an identical command after a timeout, hang, or unchanged
     result.
   - Capture and inspect the complete error or process state first.
   - If the cause cannot be determined, stop and report:
       a. the exact command,
       b. the last visible output,
       c. files changed,
       d. the suspected cause,
       e. the safest next step.

4. Run documentation generation only once per completed batch.
   - Finish all Roxygen edits first.
   - Then run `devtools::document()` once.
   - Do not repeatedly regenerate documentation after each partial edit.
   - If documentation generation fails or exceeds the timeout, diagnose the
     failure before rerunning it.

5. Use bounded execution.
   - Give every potentially long command a reasonable timeout.
   - Never leave the same command running repeatedly or launch duplicate
     background processes.
   - Check whether an earlier process is still active before starting another.

6. Verify progress after every action.
   - After each edit, state which checklist item was completed.
   - Show the relevant changed files.
   - Run the narrowest applicable test first.
   - Do not claim progress when the task list and repository state are
     unchanged.

7. Preserve scope.
   - Do not invent new functions, datasets, abstractions, or refactors unless
     required by the stated task.
   - Do not port unrelated code merely because a similar implementation exists
     elsewhere.
   - Ask before making a design decision that changes the requested estimand,
     API, data source, or output contract.

8. Protect existing work.
   - Inspect `git status` and the diff before editing.
   - Do not overwrite or revert pre-existing user changes.
   - Do not use `git reset --hard`, force push, clean, checkout-overwrite, or
     history rewriting without explicit permission.
   - Do not combine unrelated changes in one commit.

9. Git completion guard.
   - Before committing, show the exact files and diff summary.
   - If the working tree is clean, say there is nothing to commit and stop.
   - Pull with rebase only after confirming the local work is safely committed.
   - Push only the intended commit or commits.
   - Report the final commit hash, remote branch, and clean/dirty status.

10. Stop instead of thrashing.
    - If two attempts do not resolve a problem, stop.
    - Do not keep editing, rerunning, waiting, or narrating the same step.
    - Provide a concise blocker report and request a decision.

11. Completion requires evidence.
    A task is complete only when:
    - the intended code exists,
    - the diff matches the requested scope,
    - targeted tests pass,
    - documentation generation succeeds when applicable,
    - package loading/checking succeeds when applicable,
    - no unrelated files changed,
    - and the exact outputs are reported.

12. Final response format.
    Report:
    - Tasks completed
    - Files changed
    - Tests run and their outcomes
    - Documentation/package-check outcome
    - Remaining blockers
    - Git status and commit hash, if a commit was requested
