#!/usr/bin/env python3
from pathlib import Path
import sys

def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    out = root / "MANIFEST.md"
    lines = ["# Manifest", ""]
    for path in sorted(root.rglob("*")):
        if path.is_file():
            lines.append(f"- `{path.relative_to(root)}`")
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("Wrote", out)

if __name__ == "__main__":
    main()
