#!/usr/bin/env python3
"""Request a Codex review for a pull request when the two-round budget allows it.

Canonical copy: dmfenton/codex-review-gate scripts/request-review.py. Consumer repositories keep
an identical copy at scripts/request-review.py; change it here first, then copy it.

Run without --request to print the decision. With --request it posts `@codex review` only when
the PR is open, ready (not a draft), targets the base branch, and the rules below allow a round.
Counting follows the gate's README: only completed Codex outcomes consume the budget. A trigger
comment that Codex never completed does not, so a failed attempt can be requested again. A round
that reported no P0/P1 finding is final, as in the gate, so no further round is requested.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from dataclasses import dataclass
from typing import Any

Json = dict[str, Any]

BOTS = {"chatgpt-codex-connector", "chatgpt-codex-connector[bot]"}
TRUSTED = {"OWNER", "MEMBER", "COLLABORATOR"}
ROUND_BUDGET = 2  # limit: dmfenton/codex-review-gate two-round review policy (README)
RECEIPT = re.compile(r"Reviewed commit:\*\*\s*`([0-9a-f]{7,40})`")
STATE = re.compile(r"<!-- codex-review-state:v1 (\{.*?\}) -->")
SUMMARY = "<!-- codex-pull-request-review-summary -->"
REPORT = "### \U0001f4a1 Codex Review"
BLOB = re.compile(r"/blob/([0-9a-f]{40})/[^\s#]+#L\d+")
ORIGIN = re.compile(r"[:/]([^/:]+/[^/]+?)(?:\.git)?/?$")
BLOCKING = re.compile(r"\[(P0|P1)( Badge)?\]", re.IGNORECASE)
ACTIVE = {"running", "queued", "pending", "in_progress"}
RETRYABLE = {"failed", "error", "errored", "cancelled", "canceled", "timed_out"}


@dataclass(frozen=True)
class Outcome:
    commit: str
    at: str
    blocking: bool


def _bot(item: Json) -> bool:
    return item["user"]["login"] in BOTS


def _blocking(text: str) -> bool:
    return BLOCKING.search(text) is not None


def _summary_state(comment: Json) -> Json:
    match = STATE.search(comment["body"])
    state: Json = json.loads(match[1]).get("code_review") or {} if match else {}
    return state


def _review_outcomes(reviews: list[Json], review_comments: list[Json]) -> list[Outcome]:
    outcomes = []
    for review in filter(_bot, reviews):
        findings = [
            c["body"] for c in review_comments if c.get("pull_request_review_id") == review["id"]
        ]
        blocking = _blocking(review.get("body") or "") or any(map(_blocking, findings))
        outcomes.append(Outcome(review["commit_id"], review.get("submitted_at") or "", blocking))
    return outcomes


def _comment_outcome(comment: Json) -> Outcome | None:
    """A clean-review receipt, or a findings report bound by its blob links to one commit."""
    body = comment["body"]
    receipt = RECEIPT.search(body)
    if receipt:
        return Outcome(receipt[1], comment["created_at"], _blocking(body))
    commits = set(BLOB.findall(body))
    if body.lstrip().startswith(REPORT) and len(commits) == 1:
        return Outcome(commits.pop(), comment["created_at"], _blocking(body))
    return None


def _summary_outcome(comment: Json) -> Outcome | None:
    """A finding-free review recorded only by the persistent summary (plus a thumbs-up)."""
    state = _summary_state(comment)
    if state.get("status") != "completed" or state.get("has_any_findings") is not False:
        return None
    at = comment.get("updated_at") or comment["created_at"]
    return Outcome(state.get("commit_sha") or "", at, False) if state.get("commit_sha") else None


def _same_commit(a: str, b: str) -> bool:
    return a.startswith(b) or b.startswith(a)


def _summary_rounds(bot_comments: list[Json], counted: list[Outcome]) -> list[Outcome]:
    """Clean summaries whose commit no explicit outcome already covers (duplicate artifacts)."""
    summaries = [c for c in bot_comments if SUMMARY in c["body"]]
    found = [o for o in map(_summary_outcome, summaries) if o]
    return [o for o in found if not any(_same_commit(o.commit, r.commit) for r in counted)]


def completed_rounds(
    reviews: list[Json], comments: list[Json], review_comments: list[Json]
) -> list[Outcome]:
    """Every completed Codex outcome the gate recognizes, oldest first."""
    bot_comments = [c for c in comments if _bot(c)]
    reports = [c for c in bot_comments if SUMMARY not in c["body"]]
    rounds = _review_outcomes(reviews, review_comments)
    rounds += [o for o in map(_comment_outcome, reports) if o]
    rounds += _summary_rounds(bot_comments, rounds)
    return sorted(rounds, key=lambda r: r.at)


def summary_status(comments: list[Json]) -> tuple[str, str]:
    """(status, updated_at) of the connector's persistent summary, or ("", "")."""
    summaries = [c for c in comments if _bot(c) and SUMMARY in c["body"]]
    if not summaries:
        return "", ""
    latest = summaries[-1]
    status = str(_summary_state(latest).get("status") or "")
    if not status and "**Running**" in latest["body"]:
        status = "running"
    return status.lower(), latest.get("updated_at") or latest["created_at"]


def _round_block(head: str, rounds: list[Outcome]) -> str | None:
    if len(rounds) >= ROUND_BUDGET:
        return (
            "Review budget spent (two completed Codex rounds). Fix agreed P0/P1 blockers, rerun "
            "checks, resolve those threads, dispatch the gate "
            "(gh workflow run codex-p1-gate.yml -f pr_number=<PR>), and merge. "
            "Never request a third review."
        )
    if any(_same_commit(head, r.commit) for r in rounds):
        return "This head already has a completed Codex review. Do not request it again."
    if rounds and not rounds[-1].blocking:
        return (
            "The last Codex round reported no P0/P1 finding, so it was the final round. Later "
            "commits merge on the gate's descendant rule; dispatch the gate "
            "(gh workflow run codex-p1-gate.yml -f pr_number=<PR>) instead of requesting again."
        )
    return None


def _trusted_request(comment: Json, after: str) -> bool:
    return (
        not _bot(comment)
        and "@codex review" in comment["body"]
        and comment.get("author_association") in TRUSTED
        and comment["created_at"] > after
    )


def _activity_block(rounds: list[Outcome], comments: list[Json]) -> str | None:
    status, status_at = summary_status(comments)
    if status in ACTIVE:
        return "A Codex review is already running. Wait for it."
    last_done = max((r.at for r in rounds), default="")
    requests = [c for c in comments if _trusted_request(c, last_done)]
    retry = bool(requests) and status in RETRYABLE and status_at > requests[-1]["created_at"]
    if requests and not retry:
        return (
            "A review request is already pending. Wait for Codex; if it never acknowledged "
            "the request (no eyes reaction, summary unchanged), ask the owner."
        )
    return None


def decision(
    head: str, reviews: list[Json], comments: list[Json], review_comments: list[Json]
) -> tuple[bool, str]:
    rounds = completed_rounds(reviews, comments, review_comments)
    block = _round_block(head, rounds) or _activity_block(rounds, comments)
    if block:
        return False, block
    return True, f"Ready for review round {len(rounds) + 1}/{ROUND_BUDGET}."


def gh(*args: str) -> Any:
    return json.loads(subprocess.check_output(["gh", *args], text=True))


def origin_repo() -> str:
    """owner/name from origin; `gh repo view` needs GraphQL, which cloud sessions lack."""
    url = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
    match = ORIGIN.search(url)
    if not match:
        raise SystemExit("Cannot read owner/name from the origin remote; pass --repo.")
    return match[1]


def pages(resource: str) -> list[Json]:
    return [item for page in gh("api", "--paginate", "--slurp", resource) for item in page]


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("pr", type=int)
    parser.add_argument("--request", action="store_true", help="post the request when eligible")
    parser.add_argument("--repo", help="owner/name; defaults to the current checkout's repository")
    parser.add_argument("--base", default="main", help="required base branch (default main)")
    args = parser.parse_args()
    repo = args.repo or origin_repo()
    pr = gh("api", f"repos/{repo}/pulls/{args.pr}")
    if pr["state"] != "open" or pr["base"]["ref"] != args.base:
        print(f"Review requests require an open PR targeting {args.base}.")
        return 1
    if pr["draft"]:
        ready = f"gh api -X POST repos/{repo}/pulls/{args.pr}/ccr/ready_for_review"
        print(
            f"PR is a draft. When it is ready, mark it ready (`gh pr ready {args.pr}`; "
            f"in a Claude cloud session `{ready}`) and request again."
        )
        return 1
    allowed, message = decision(
        pr["head"]["sha"],
        pages(f"repos/{repo}/pulls/{args.pr}/reviews?per_page=100"),
        pages(f"repos/{repo}/issues/{args.pr}/comments?per_page=100"),
        pages(f"repos/{repo}/pulls/{args.pr}/comments?per_page=100"),
    )
    print(message)
    if not allowed:
        return 1
    if args.request:
        endpoint = f"repos/{repo}/issues/{args.pr}/comments"
        post = ["gh", "api", "--method", "POST", endpoint, "-f", "body=@codex review", "--silent"]
        subprocess.run(post, check=True)
        print(f"Requested Codex review on {repo}#{args.pr}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
