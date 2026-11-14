---
name: pr
description: Validate a Touch Grass change, open its PR, request the Codex review immediately, and take it through the two-round review gate and CI to merge. Use for "pr this", "/pr", "open a PR", or any request for a pull request.
---

# pr

The only supported route to opening and landing a Touch Grass pull request.

## Validate

1. Fetch `origin/main` and update the branch from it; after a review, merge `main` rather than
   rebasing so the reviewed commit stays in the branch's history.
2. Inspect the complete diff. Run the checks for what changed, as listed in `AGENTS.md`:
   - iOS (`ios/`): `bash scripts/ios-check.sh`.
   - macOS app at the repository root: `bash scripts/test.sh` and `bash scripts/lint.sh`.
   Never swallow a test or lint failure. If a tool is unavailable on this host (Xcode, SwiftLint,
   a simulator lease), name that gap in the PR body instead of implying it passed.
3. Review the diff for private calendar data, signing material and generated artifacts.

## Open, review and land

This part is the same in every repository that uses `dmfenton/codex-review-gate`. Codex does not
review drafts, and marking a PR ready has not reliably started a review, so the review is always
requested explicitly, right after the PR is ready.

1. Push the branch and open the PR against `main`. A draft is fine while work continues.
2. When validation is green and the change is complete, mark it ready and immediately request the
   review. `gh pr ready <PR>` uses GraphQL, which Claude cloud sessions cannot reach; there use
   `gh api -X POST repos/<owner>/<repo>/pulls/<PR>/ccr/ready_for_review`. Then:
   `python3 scripts/request-review.py <PR> --request`
   Without `--request` the script only reports whether a request is allowed. Never post
   `@codex review` by hand: the script refuses a draft, a head that already has a review, a review
   that is running or pending, and a third round.
3. Wait for CI and the review. Triage every finding in one pass, by this repository's review
   rule: fix P0/P1 findings and anything that will actually bite; answer the rest on the thread
   with a one-line reason, then resolve it.
4. If round 1 reported P0/P1 findings, push all fixes together, rerun the checks, and request round
   2 with the same command. Round 2 is final. A round with no P0/P1 finding is already final.
5. After the final round, fix any remaining blockers in child commits (never amend or rebase the
   reviewed commit), rerun the checks, resolve those threads, and dispatch the gate:
   `gh workflow run codex-p1-gate.yml -f pr_number=<PR>`. Never request a third review or open a
   replacement PR to reset the budget.
6. Merge when the `Codex review gate` status and every repository check are green and live
   `reviewThreads` shows zero unresolved Codex threads (in a Claude cloud session, read
   `gh api repos/<owner>/<repo>/pulls/<PR>/ccr/review_threads`). Merging is not deploying.

The gate publishes "Exact-head Codex review is not ready" for every failure, including an open
P0/P1 thread or a non-`main` base. Open the status link and read the run log for the real reason
before acting. Dependabot PRs always fail the gate by design; do not request reviews on them.

`scripts/request-review.py` is a copy of the canonical script in `dmfenton/codex-review-gate`;
change it there first, then copy it here unchanged.
