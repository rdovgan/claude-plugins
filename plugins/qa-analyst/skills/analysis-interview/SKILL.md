---
name: analysis-interview
description: Phase 2 of a QA analysis - close the gaps by interviewing the QA engineer, and write 02-interview.md. Run by /qa-analyst:analyze after analysis-research; also use whenever a QA task has unclear expected behaviour, environment or scope.
allowed-tools: AskUserQuestion, Read, Grep, Glob, Edit, Write
---

# analysis-interview

Phase 2. **No code changes.** The interview is **interactive**: every question is asked with the `AskUserQuestion` tool, never as a list in plain text. The only file you write is `.claude/qa-analysis/<task>/02-interview.md`.

The user is a QA engineer. Ask in their terms (screens, statuses, users, environments, partners, test data), never in code terms (classes, methods, exceptions). If a technical detail matters, explain it in one plain sentence inside the option description.

## Steps

1. Re-read `01-research.md`, especially "Understanding", "Requirements", "Evidence" and "Open questions". The user gave you the ticket, the pages and the logs so they would not have to repeat them: asking what the sources already say is the worst failure of this phase.
2. Build candidate questions from the open questions of `01-research.md`. Then go through this checklist of **places where gaps hide** (not questions to ask): which environment (prod, stage, demo) and which build or date; which user, role, account, partner or channel; the time window and the ids of the case; is it reproducible, always or sometimes; which source defines the expected behaviour; edge cases and negative cases; error messages the user should see; data and preconditions needed for testing; integrations and other systems involved; what is in and out of the test scope; regression areas; severity and priority. A checklist item becomes a question only if it matters for this task and nothing answers it.
3. **Filter every candidate against the sources** before asking it: the requirements `R*`, the Confluence pages (text and comments), the ticket and its comments, the logs, the code, the DB. For each candidate:
   - answered clearly -> drop it; it is not a question;
   - answered, but the wording allows two readings -> ask to confirm your reading, quoting the source: "Page X says: "...". I read it as A. Correct?";
   - not answered anywhere -> ask it.
   If you are unsure whether a page covers it, open the page again; do not ask from memory of a summary.
4. Load `AskUserQuestion` with `ToolSearch("select:AskUserQuestion")` if its schema is not available, then call it right away. Invoking this skill is the go-ahead; do not print the questions first and do not ask "shall I start?".
5. **First call: confirm the understanding.** Print the "Understanding" section and the key requirements (5-10 lines, with `R*` ids, plain language) as plain text, then ask with `AskUserQuestion` whether it is right: "Correct" (Recommended) / "Partly - I will correct it" / "Wrong". You may add up to three of your filtered questions to the same call. If the user corrects you, update `01-research.md` and re-filter the questions before going on.
6. Ask 1-4 questions per call, ordered so an answer can change the next: first what decides the verdict (expected behaviour, environment, the case itself), then details (test data, scope). Dependent questions go in a later call.
7. Every question has 2-4 options with a short description, the recommended default first, marked `(Recommended)`. "Other" for free text is always available. Put the reason behind the recommendation in the option description, and the source (`R*`, page, log line) when there is one.
8. Something only the user can provide (a log, a screenshot, a request or response body, ids of the case, the time it happened) cannot be an option: ask for it as a plain-text request after the choice questions and record it as open if skipped. When it arrives, update the evidence in `01-research.md`.
9. Never invent answers. An unanswered or skipped question is recorded as open.
10. If the user declines the tool call, stop and wait. Do not fall back to a text list.
11. **Zero questions beyond the confirmation is a good result** when the sources answer everything. Do not ask to fill the template.
12. Finish when all questions are closed or the user says to continue. Fill `${CLAUDE_PLUGIN_ROOT}/templates/analysis/02-interview.md` and save it to `.claude/qa-analysis/<task>/02-interview.md`: the confirmation of the understanding, each question with the options offered, the decision and its reason, the questions dropped because the sources answer them, the information the user provided, then the open questions.

Questions must be concrete and specific to this task, not generic advice. Then continue with `analysis-report` in the same turn.
