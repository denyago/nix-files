#!/usr/bin/env python3
"""CVE audit helper for my-nix. Wraps vulnix with score filtering and whitelist management."""

import argparse
import datetime
import json
import os
import re
import subprocess
import sys
import tempfile


def run_vulnix_json(system_path: str, whitelist: str | None) -> list:
    cmd = ["vulnix", "--closure", system_path, "--json"]
    if whitelist and os.path.exists(whitelist):
        cmd += ["-w", whitelist]
    result = subprocess.run(cmd, capture_output=True, text=True)
    raw = result.stdout.strip()
    if not raw or raw == "[]":
        return []
    return json.loads(raw)


def append_whitelist(findings: list, cve_ids: set[str], whitelist: str, expiry_days: int) -> int:
    """Append whitelist TOML entries for the given CVE IDs. Returns number of entries written."""
    until = (datetime.date.today() + datetime.timedelta(days=expiry_days)).isoformat()

    lines = []
    for pkg in sorted(findings, key=lambda p: p["name"]):
        pkg_cves = sorted(set(pkg.get("affected_by", [])) & cve_ids)
        if not pkg_cves:
            continue
        name = pkg["name"]
        if len(pkg_cves) == 1:
            lines.append(f'["{name}"]\ncve = "{pkg_cves[0]}"\nuntil = "{until}"')
        else:
            cves_str = ", ".join(f'"{c}"' for c in pkg_cves)
            lines.append(f'["{name}"]\ncve = [ {cves_str} ]\nuntil = "{until}"')

    if not lines:
        return 0

    existing = ""
    if os.path.exists(whitelist):
        with open(whitelist) as f:
            existing = f.read()

    with open(whitelist, "w") as f:
        f.write(existing)
        if existing and not existing.endswith("\n"):
            f.write("\n")
        f.write("\n".join(lines) + "\n")

    return len(lines)


def cmd_init(system_path: str, whitelist: str, threshold: float, expiry_days: int) -> None:
    print(f"🔍 Scanning {system_path} for CVEs below score {threshold} to whitelist…")

    # Run without whitelist filter to see everything
    findings = run_vulnix_json(system_path, None)
    if not findings:
        print("✅ No findings.")
        return

    below_ids: set[str] = set()
    for pkg in findings:
        scores = pkg.get("cvssv3_basescore", {})
        for cve_id in pkg.get("affected_by", []):
            if float(scores.get(cve_id) or 0) < threshold:
                below_ids.add(cve_id)

    if not below_ids:
        print(f"✅ Nothing below threshold {threshold} to whitelist.")
        return

    count = append_whitelist(findings, below_ids, whitelist, expiry_days)
    print(f"✅ Whitelisted {count} package entry/entries ({len(below_ids)} CVEs below {threshold}) → {whitelist}")


def prompt_action(flagged: list, findings: list, system_path: str, whitelist: str, yes: bool, expiry_days: int, threshold: float) -> None:
    """Prompt the user and act on their choice. Exits non-zero on N."""
    expiry_date = (datetime.date.today() + datetime.timedelta(days=expiry_days)).isoformat()

    if yes:
        all_ids = {cve for _, cves, _ in flagged for cve in cves}
        count = append_whitelist(findings, all_ids, whitelist, expiry_days)
        print(f"✅ Whitelisted {count} package entry/entries (until {expiry_date}) → {whitelist}")
        return

    if not sys.stdin.isatty():
        print("⚠️  Non-interactive mode: aborting due to unresolved CVEs.")
        sys.exit(1)

    answer = input("\nShall we not continue (N) / accept all (A|Y) / edit the list (E)? [N] ").strip().upper()

    if answer in ("A", "Y"):
        all_ids = {cve for _, cves, _ in flagged for cve in cves}
        count = append_whitelist(findings, all_ids, whitelist, expiry_days)
        print(f"✅ Whitelisted {count} package entry/entries (until {expiry_date}) → {whitelist}")

    elif answer == "E":
        lines = []
        for name, cves, scores in sorted(flagged):
            for cve_id in sorted(cves, key=lambda c: float(scores.get(c) or 0), reverse=True):
                lines.append(f"{cve_id}  # {name}  CVSSv3={scores.get(cve_id, 'N/A')}")

        with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as tmp:
            tmp.write("# Delete lines for CVEs you do NOT want to accept.\n")
            tmp.write(f"# Save and close to whitelist the remaining entries (until {expiry_date}).\n\n")
            tmp.write("\n".join(lines) + "\n")
            tmp_path = tmp.name

        editor = os.environ.get("EDITOR", "vi")
        subprocess.run([editor, tmp_path])

        with open(tmp_path) as f:
            kept = {
                l.split()[0] for l in f
                if l.strip() and not l.startswith("#")
            }
        os.unlink(tmp_path)

        if not kept:
            print("No CVEs selected — aborting.")
            sys.exit(1)

        count = append_whitelist(findings, kept, whitelist, expiry_days)
        print(f"✅ Whitelisted {count} package entry/entries ({len(kept)} CVEs, until {expiry_date}) → {whitelist}")

        # Re-evaluate with the updated whitelist
        print("\n🔄 Re-running CVE check with updated whitelist…")
        findings = run_vulnix_json(system_path, whitelist)
        flagged = []
        for pkg in findings:
            scores = pkg.get("cvssv3_basescore", {})
            high = [
                cve_id for cve_id in pkg.get("affected_by", [])
                if float(scores.get(cve_id) or 0) >= threshold
            ]
            if high:
                flagged.append((pkg["name"], high, scores))

        if not flagged:
            print(f"✅ No remaining CVEs at or above score {threshold}.")
            return

        sep = "-" * 72
        print(f"\n{len(flagged)} remaining package(s) with CVSSv3 ≥ {threshold}:\n")
        for name, cves, scores in sorted(flagged):
            print(sep)
            print(name)
            print(f"  {'CVE':<50} CVSSv3")
            for cve_id in sorted(cves, key=lambda c: float(scores.get(c) or 0), reverse=True):
                url = f"https://nvd.nist.gov/vuln/detail/{cve_id}"
                print(f"  {url:<50} {scores.get(cve_id, 'N/A')}")
        print(sep)

        prompt_action(flagged, findings, system_path, whitelist, yes, expiry_days, threshold)

    else:
        print("Aborting.")
        sys.exit(1)


def cmd_audit(system_path: str, whitelist: str, threshold: float, yes: bool, expiry_days: int) -> None:
    print(f"🔍 CVE audit of {system_path} (CVSSv3 ≥ {threshold})…")

    findings = run_vulnix_json(system_path, whitelist)

    flagged = []
    for pkg in findings:
        scores = pkg.get("cvssv3_basescore", {})
        high = [
            cve_id for cve_id in pkg.get("affected_by", [])
            if float(scores.get(cve_id) or 0) >= threshold
        ]
        if high:
            flagged.append((pkg["name"], high, scores))

    if not flagged:
        print(f"✅ No CVEs at or above score {threshold}.")
        return

    sep = "-" * 72
    print(f"\n{len(flagged)} package(s) with CVSSv3 ≥ {threshold}:\n")
    for name, cves, scores in sorted(flagged):
        print(sep)
        print(name)
        print(f"  {'CVE':<50} CVSSv3")
        for cve_id in sorted(cves, key=lambda c: float(scores.get(c) or 0), reverse=True):
            url = f"https://nvd.nist.gov/vuln/detail/{cve_id}"
            print(f"  {url:<50} {scores.get(cve_id, 'N/A')}")
    print(sep)

    prompt_action(flagged, findings, system_path, whitelist, yes, expiry_days, threshold)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="CVE audit helper — wraps vulnix with score filtering and whitelist management.",
    )
    parser.add_argument("path", help="System/closure path to audit (e.g. ./result)")
    parser.add_argument(
        "--init",
        action="store_true",
        help="Write CVEs below --min-score to whitelist and exit.",
    )
    parser.add_argument(
        "--min-score",
        type=float,
        default=9.0,
        metavar="N",
        help="Only report/keep CVEs with CVSSv3 >= N (default: 9.0).",
    )
    parser.add_argument(
        "--whitelist",
        default=os.path.join(os.environ.get("MY_NIX_DIR", "."), "vulnix-whitelist.toml"),
        metavar="FILE",
        help="Path to whitelist TOML (default: $MY_NIX_DIR/vulnix-whitelist.toml).",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Non-interactive: accept all findings (whitelist them) without prompting.",
    )
    parser.add_argument(
        "--expiry-days",
        type=int,
        default=7,
        metavar="N",
        help="Days until whitelist entries expire (default: 7).",
    )
    args = parser.parse_args()

    if args.init:
        cmd_init(args.path, args.whitelist, args.min_score, args.expiry_days)
    else:
        cmd_audit(args.path, args.whitelist, args.min_score, args.yes, args.expiry_days)


if __name__ == "__main__":
    main()
