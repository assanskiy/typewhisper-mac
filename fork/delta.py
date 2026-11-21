#!/usr/bin/env python3
"""The fork's delta over upstream: one row per commit in BASE..HEAD.

    python3 fork/delta.py                 # table of main..fork
    python3 fork/delta.py --check         # exit 1 if a delta commit lacks a valid Fork-Delta trailer
    python3 fork/delta.py --online        # also asks GitHub for each Upstream-PR state
    python3 fork/delta.py --base X --head Y
"""
import argparse
import json
import subprocess
import sys
import urllib.request

UPSTREAM = "TypeWhisper/typewhisper-mac"
KINDS = {"upstream-pr", "fork-only"}
SEP = "\x1f"


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def trailer(name):
    return f"%(trailers:key={name},valueonly,separator=%x2C)"


def commits(base, head):
    fmt = SEP.join(["%h", "%s", trailer("Fork-Delta"), trailer("Upstream-Issue"), trailer("Upstream-PR")])
    out = git("log", "--reverse", f"--format={fmt}%x1e", f"{base}..{head}", "--")
    rows = []
    for rec in out.split("\x1e"):
        rec = rec.strip("\n")
        if not rec:
            continue
        sha, subject, kind, issue, pr = (part.strip() for part in rec.split(SEP))
        rows.append({"sha": sha, "subject": subject, "kind": kind, "issue": issue, "pr": pr})
    return rows


def pr_state(pr):
    num = pr.lstrip("#")
    if not num.isdigit():
        return "?"
    url = f"https://api.github.com/repos/{UPSTREAM}/pulls/{num}"
    try:
        with urllib.request.urlopen(url, timeout=15) as resp:
            body = json.load(resp)
    except OSError:
        return "?"
    return "merged" if body.get("merged_at") else body.get("state", "?")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="main")
    ap.add_argument("--head", default="HEAD")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--online", action="store_true")
    a = ap.parse_args()

    rows = commits(a.base, a.head)
    bad = [r for r in rows if r["kind"] not in KINDS or (r["kind"] == "upstream-pr" and not r["issue"])]
    for r in rows:
        state = pr_state(r["pr"]) if a.online and r["pr"] else ""
        print("\t".join([r["sha"], r["kind"] or "-", r["issue"] or "-", r["pr"] or "-", state, r["subject"]]))
    print(f"delta: {len(rows)} commits over {a.base}", file=sys.stderr)
    if a.check and bad:
        for r in bad:
            print(f"missing or invalid Fork-Delta/Upstream-Issue trailer: {r['sha']} {r['subject']}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
