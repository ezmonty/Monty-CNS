#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT_FILES = [
    "README.md",
    "VAULT_RULES.md",
    "AI_USAGE.md",
    "MODE_AND_ACCESS_MODEL.md",
    "PARA_AND_OVERLAY.md",
    "CLAUDE.md",
]

def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    print("Vault quick check")
    missing = [f for f in ROOT_FILES if not (root / f).exists()]
    if missing:
        print("Missing root files:")
        for m in missing:
            print(" -", m)
    else:
        print("Root files present.")

    profile_dir = root / "03_Profiles"
    if profile_dir.exists():
        profiles = sorted(p.name for p in profile_dir.glob("Profile - *.md"))
        print(f"Profiles found: {len(profiles)}")
        for p in profiles:
            print(" -", p)
    else:
        print("No 03_Profiles folder found.")

if __name__ == "__main__":
    main()
