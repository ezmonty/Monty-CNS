#!/usr/bin/env python3
from pathlib import Path
import re
import sys

REQUIRED = ["type:", "status:", "created:", "updated:", "tags:", "confidence:", "access:", "truth_layer:", "role_mode:"]

def has_frontmatter(text: str) -> bool:
    return text.startswith("---\n")

def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    problems = []
    for path in root.rglob("*.md"):
        if ".obsidian" in path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        if not has_frontmatter(text) and "README" not in path.name and "START_HERE" not in path.name and path.parts[-2] != "10_Dashboards" and path.parts[-2] != "15_Agent_Prompts":
            problems.append((path, "missing frontmatter"))
            continue
        if has_frontmatter(text):
            header = text.split("---", 2)[1]
            for req in REQUIRED:
                if req not in header:
                    problems.append((path, f"missing field {req}"))
    if not problems:
        print("No frontmatter problems found.")
    else:
        for p, issue in problems:
            print(f"{p}: {issue}")

if __name__ == "__main__":
    main()
