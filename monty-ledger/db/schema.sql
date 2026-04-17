-- Monty-Ledger PostgreSQL schema.
-- This is the query layer. Markdown files are the source of truth.
-- Populated by scripts/sync_to_postgres.py.

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS notes (
    id              TEXT PRIMARY KEY,
    path            TEXT NOT NULL UNIQUE,
    type            TEXT,
    title           TEXT NOT NULL,
    status          TEXT DEFAULT 'active',
    access          TEXT DEFAULT 'private' CHECK (access IN ('public', 'private', 'secret', 'hidden')),
    truth_layer     TEXT DEFAULT 'working' CHECK (truth_layer IN ('raw', 'working', 'output', 'hidden')),
    mask_level      TEXT DEFAULT 'none' CHECK (mask_level IN ('none', 'low', 'medium', 'high')),
    role_mode       TEXT,
    confidence      INTEGER CHECK (confidence BETWEEN 1 AND 5),
    origin_type     TEXT,
    frontmatter     JSONB NOT NULL DEFAULT '{}',
    content         TEXT NOT NULL DEFAULT '',
    content_hash    TEXT NOT NULL,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tags (
    note_id         TEXT NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    tag             TEXT NOT NULL,
    PRIMARY KEY (note_id, tag)
);

CREATE TABLE IF NOT EXISTS links (
    source_id       TEXT NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    target_path     TEXT NOT NULL,
    link_text       TEXT,
    PRIMARY KEY (source_id, target_path)
);

CREATE TABLE IF NOT EXISTS persona_mix (
    note_id         TEXT NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    persona         TEXT NOT NULL,
    PRIMARY KEY (note_id, persona)
);

-- Indexes for the queries agents actually run.
CREATE INDEX IF NOT EXISTS idx_notes_type ON notes(type);
CREATE INDEX IF NOT EXISTS idx_notes_access ON notes(access);
CREATE INDEX IF NOT EXISTS idx_notes_truth_layer ON notes(truth_layer);
CREATE INDEX IF NOT EXISTS idx_notes_role_mode ON notes(role_mode);
CREATE INDEX IF NOT EXISTS idx_notes_confidence ON notes(confidence);
CREATE INDEX IF NOT EXISTS idx_notes_origin_type ON notes(origin_type);
CREATE INDEX IF NOT EXISTS idx_notes_frontmatter ON notes USING GIN (frontmatter);
CREATE INDEX IF NOT EXISTS idx_notes_content_search ON notes USING GIN (content gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_tags_tag ON tags(tag);
CREATE INDEX IF NOT EXISTS idx_links_target ON links(target_path);
