-- Useful views for common agent queries.

CREATE OR REPLACE VIEW v_profiles AS
SELECT id, path, title, role_mode, confidence, frontmatter, content
FROM notes WHERE type = 'profile' AND access IN ('public', 'private');

CREATE OR REPLACE VIEW v_decisions AS
SELECT id, path, title, status, confidence, created_at, frontmatter, content
FROM notes WHERE type = 'decision' AND access IN ('public', 'private')
ORDER BY created_at DESC;

CREATE OR REPLACE VIEW v_evidence AS
SELECT id, path, title, confidence, origin_type, created_at, frontmatter, content
FROM notes WHERE type = 'evidence' AND access IN ('public', 'private')
ORDER BY confidence DESC, created_at DESC;

CREATE OR REPLACE VIEW v_inbox AS
SELECT id, path, title, origin_type, created_at, frontmatter, content
FROM notes WHERE path LIKE '00_Inbox/%'
ORDER BY created_at DESC;

CREATE OR REPLACE VIEW v_pods AS
SELECT id, path, title, frontmatter, content
FROM notes WHERE path LIKE '13_Pods/%';
