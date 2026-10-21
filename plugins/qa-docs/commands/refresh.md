---
description: Bring a documented domain up to date with the current code - find what changed since it was documented, re-check the affected statements, re-verify
argument-hint: <domain slug>
---

Refresh the domain `$ARGUMENTS`.

1. Read `qa-docs/domains/$ARGUMENTS/meta.json` and `domain.md`. For each repository in `modules`, compare the recorded commit with the current one. Unchanged everywhere: say so and stop.
2. For changed repositories: `git -C <repo> log --oneline <old>..HEAD` and `git -C <repo> diff --stat <old>..HEAD`. Find the changed files that the document cites, and changed files on the domain's call paths (grep the entry points and the classes the document names). Read those diffs.
3. For each statement whose code changed: re-check it with your own reading, or with `flow-tracer` agents for larger changes (at most `QA_DOCS_MAX_SUBFLOWS`, default 6, and only on the changed call paths), then correct `02-code.md` and `domain.md`. Look for new behaviour too: a new branch, status, setting or integration. Also re-check `01-sources.md` against Jira for tickets resolved since `updatedAt` that touch the domain.
4. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-refs.sh qa-docs/domains/$ARGUMENTS`: line numbers move even when behaviour does not; fix them all.
5. Update `meta.json` (`modules`, `updatedAt`, `updatedBy`, `status` back to `draft` if behaviour changed), and append to `history.md` what changed in the code and in the document.
6. If behaviour changed, run `domain-verify`. If only references moved, say so; the previous approval stands and the status stays.
7. Finish with what changed, in one short list, and `/qa-docs:export $ARGUMENTS` if the page is out of date.
