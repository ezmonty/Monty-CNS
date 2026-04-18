#!/usr/bin/env python3
from pathlib import Path
import json
import sys
import re

def clean(name: str) -> str:
    name = (name or "untitled").strip()
    name = re.sub(r"[^\w\s-]", "", name)
    name = re.sub(r"\s+", " ", name).strip()
    return name[:80] or "untitled"

def main():
    if len(sys.argv) < 2:
        print("Usage: split_conversations_json.py /path/to/conversations.json [output_dir]")
        sys.exit(1)

    src = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else src.parent / "split_conversations"
    out.mkdir(parents=True, exist_ok=True)

    data = json.loads(src.read_text(encoding="utf-8"))
    count = 0
    for i, convo in enumerate(data):
        title = clean(convo.get("title", f"conversation-{i+1}"))
        filename = f"{i+1:04d} - {title}.json"
        (out / filename).write_text(json.dumps(convo, indent=2, ensure_ascii=False), encoding="utf-8")
        count += 1

    print(f"Wrote {count} conversation files to {out}")

if __name__ == "__main__":
    main()
