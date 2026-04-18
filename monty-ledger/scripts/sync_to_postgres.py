#!/usr/bin/env python3
"""Sync markdown vault files to PostgreSQL.

Reads every .md file under the vault root, parses YAML frontmatter,
and upserts into the notes/tags/links/persona_mix tables. Idempotent:
uses content_hash to skip unchanged files.

Usage:
    LEDGER_DATABASE_URL=postgresql://... python scripts/sync_to_postgres.py [vault_root]

If vault_root is omitted, defaults to the directory containing this script's parent.
"""

import hashlib
import os
import re
import sys
from pathlib import Path

try:
    import frontmatter
except ImportError:
    sys.exit("Missing dependency: pip install python-frontmatter")

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    sys.exit("Missing dependency: pip install psycopg2-binary")

import json

WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

def get_vault_root():
    if len(sys.argv) > 1:
        return Path(sys.argv[1])
    return Path(__file__).resolve().parent.parent

def _safe_date(val):
    if val is None:
        return None
    s = str(val).strip()
    if s.startswith('<%') or not s or not s[0].isdigit():
        return None
    return s

def compute_hash(content: str) -> str:
    return hashlib.sha256(content.encode()).hexdigest()[:16]

def extract_wikilinks(content: str) -> list[str]:
    return list(set(WIKILINK_RE.findall(content)))

FM_RE = re.compile(r'^---\s*\n(.*?)\n---\s*\n', re.DOTALL)

def parse_note(path: Path, vault_root: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    try:
        post = frontmatter.loads(text)
        fm = dict(post.metadata)
        body = post.content
    except Exception:
        fm = {}
        m = FM_RE.match(text)
        if m:
            for line in m.group(1).splitlines():
                if ':' in line and not line.startswith('#'):
                    key, _, val = line.partition(':')
                    key = key.strip()
                    val = val.strip().strip('"').strip("'")
                    if val.startswith('[') and val.endswith(']'):
                        val = [v.strip().strip('"').strip("'") for v in val[1:-1].split(',')]
                    fm[key] = val
            body = text[m.end():]
        else:
            body = text
    rel_path = str(path.relative_to(vault_root))
    title = fm.get("summary") or path.stem.replace(" - ", " — ")
    return {
        "id": fm.get("id") or rel_path,
        "path": rel_path,
        "type": fm.get("type"),
        "title": title,
        "status": fm.get("status", "active"),
        "access": fm.get("access", "private"),
        "truth_layer": fm.get("truth_layer", "working"),
        "mask_level": fm.get("mask_level", "none"),
        "role_mode": fm.get("role_mode"),
        "confidence": fm.get("confidence"),
        "origin_type": fm.get("origin_type"),
        "frontmatter": json.dumps(fm, default=str),
        "content": body,
        "content_hash": compute_hash(text),
        "created_at": _safe_date(fm.get("created")),
        "updated_at": _safe_date(fm.get("updated")),
        "tags": fm.get("tags", []) or [],
        "persona_mix": fm.get("persona_mix", []) or [],
        "links": extract_wikilinks(body),
    }

def sync(vault_root: Path, db_url: str):
    conn = psycopg2.connect(db_url)
    conn.autocommit = False
    cur = conn.cursor()

    existing = {}
    cur.execute("SELECT path, content_hash FROM notes")
    for row in cur.fetchall():
        existing[row[0]] = row[1]

    EXCLUDE_DIRS = {'node_modules', 'mcp-server', 'db', '.git', '__pycache__', 'dist'}
    md_files = sorted(
        f for f in vault_root.rglob("*.md")
        if not any(ex in f.parts for ex in EXCLUDE_DIRS)
    )
    synced = skipped = 0

    for f in md_files:
        if f.name.startswith("."):
            continue
        try:
            note = parse_note(f, vault_root)
        except Exception as e:
            print(f"  SKIP {f}: {e}", file=sys.stderr)
            skipped += 1
            continue

        if existing.get(note["path"]) == note["content_hash"]:
            continue

        cur.execute("DELETE FROM notes WHERE path = %s", (note["path"],))
        cur.execute("""
            INSERT INTO notes (id, path, type, title, status, access, truth_layer,
                mask_level, role_mode, confidence, origin_type, frontmatter,
                content, content_hash, created_at, updated_at)
            VALUES (%(id)s, %(path)s, %(type)s, %(title)s, %(status)s, %(access)s,
                %(truth_layer)s, %(mask_level)s, %(role_mode)s, %(confidence)s,
                %(origin_type)s, %(frontmatter)s, %(content)s, %(content_hash)s,
                %(created_at)s, %(updated_at)s)
        """, note)

        if note["tags"]:
            psycopg2.extras.execute_values(cur,
                "INSERT INTO tags (note_id, tag) VALUES %s",
                [(note["id"], t) for t in note["tags"]])

        if note["persona_mix"]:
            psycopg2.extras.execute_values(cur,
                "INSERT INTO persona_mix (note_id, persona) VALUES %s",
                [(note["id"], p) for p in note["persona_mix"]])

        if note["links"]:
            psycopg2.extras.execute_values(cur,
                "INSERT INTO links (source_id, target_path, link_text) VALUES %s",
                [(note["id"], lnk, lnk) for lnk in note["links"]])

        synced += 1

    vault_paths = {str(f.relative_to(vault_root)) for f in md_files}
    orphaned = set(existing.keys()) - vault_paths
    if orphaned:
        cur.execute("DELETE FROM notes WHERE path = ANY(%s)", (list(orphaned),))
        print(f"  Removed {len(orphaned)} orphaned records")

    conn.commit()
    cur.close()
    conn.close()
    print(f"Synced {synced} notes, skipped {skipped}, total {len(md_files)} files")

if __name__ == "__main__":
    vault_root = get_vault_root()
    db_url = os.environ.get("LEDGER_DATABASE_URL")
    if not db_url:
        sys.exit("Set LEDGER_DATABASE_URL environment variable")
    print(f"Syncing {vault_root} → PostgreSQL")
    sync(vault_root, db_url)
