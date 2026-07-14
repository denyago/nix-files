#!/usr/bin/env python3
"""CVE audit helper for my-nix. Wraps vulnix with score filtering and whitelist management."""

import argparse
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


def run_vulnix_write_whitelist(system_path: str, dest: str, existing_whitelist: str | None) -> None:
    cmd = ["vulnix", "--closure", system_path, "--write-whitelist", dest]
    if existing_whitelist and os.path.exists(existing_whitelist):
        cmd += ["-w", existing_whitelist]
    subprocess.run(cmd, capture_output=True)


def filter_blocks_below_threshold(toml_content: str, threshold: float) -> list[str]:
    blocks = re.split(r"(?=\[\[advisories\]\])", toml_content)
    result = []
    for block in blocks:
        if not block.strip().startswith("[[advisories]]"):
            continue
        scores = [float(s) for s in re.findall(r"cvssv3\s*=\s*([\d.]+)", block)]
        if not scores or max(scores) < threshold:
            result.append(block)
    return result


def cmd_init(system_path: str, whitelist: str, threshold: float) -> None:
    print(f"🔍 Scanning {system_path} for CVEs below score {threshold} to whitelist…")

    with tempfile.NamedTemporaryFile(suffix=".toml", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        run_vulnix_write_whitelist(system_path, tmp_path, whitelist)

        if not os.path.exists(tmp_path) or os.path.getsize(tmp_path) == 0:
            print("✅ No findings to whitelist.")
            return

        with open(tmp_path) as f:
            content = f.read()

        blocks = filter_blocks_below_threshold(content, threshold)

        if not blocks:
            print(f"✅ Nothing below threshold {threshold} to whitelist.")
            return

        existing = ""
        if os.path.exists(whitelist):
            with open(whitelist) as f:
                existing = f.read()

        with open(whitelist, "w") as f:
            f.write(existing)
            if existing and not existing.endswith("\n"):
                f.write("\n")
            f.write("".join(blocks))

        print(f"✅ Whitelisted {len(blocks)} finding(s) below score {threshold} → {whitelist}")
    finally:
        os.unlink(tmp_path)


def cmd_audit(system_path: str, whitelist: str, threshold: float) -> None:
    print(f"🔍 CVE audit of {system_path} (CVSSv3 ≥ {threshold})…")

    findings = run_vulnix_json(system_path, whitelist)

    flagged = []
    for pkg in findings:
        high = [
            c for c in pkg.get("affected_by", [])
            if float(c.get("cvssv3") or 0) >= threshold
        ]
        if high:
            flagged.append((pkg["name"], high))

    if not flagged:
        print(f"✅ No CVEs at or above score {threshold}.")
        return

    sep = "-" * 72
    print(f"\n{len(flagged)} package(s) with CVSSv3 ≥ {threshold}:\n")
    for name, cves in sorted(flagged):
        print(sep)
        print(name)
        print(f"  {'CVE':<50} CVSSv3")
        for c in sorted(cves, key=lambda x: float(x.get("cvssv3") or 0), reverse=True):
            url = f"https://nvd.nist.gov/vuln/detail/{c['cve_id']}"
            print(f"  {url:<50} {c['cvssv3']}")
    print(sep)


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
    args = parser.parse_args()

    if args.init:
        cmd_init(args.path, args.whitelist, args.min_score)
    else:
        cmd_audit(args.path, args.whitelist, args.min_score)


if __name__ == "__main__":
    main()
