# Assets

Physical source material — ingested documents, attachments, exports, screenshots.

## What goes here

- PDFs of papers, specs, tool docs, regulatory docs, research sources
- Scraped web articles and tool documentation
- Screenshots and screen recordings
- Vault exports (JSON, CSV, Postgres dumps)

## Folder structure

```
09_Assets/
  agent-design/     # research docs on agent architectures, frameworks, papers
  construction/     # construction industry specs, regulatory, OSHA, AIA docs
  finance/          # financial research, CFA materials, market docs
  ml/               # ML/AI papers and technical docs
  infra/            # infrastructure, ops, cloud docs
  vault/            # vault-related specs and references
  exports/          # vault exports
  screenshots/      # UI captures
```

## RAG ingestion

When a document is ingested here, update the corresponding `08_Knowledge/Research - *.md` note:
- Set `ingested: true`
- Set `asset_path: 09_Assets/[domain]/[filename]`

Both the research note (evaluated summary) and the asset (raw content) chunk into RAG.
The research note provides verdict and decision context; the asset provides full content retrieval.

## Naming convention

`[YYYY-MM-DD]-[short-slug].[ext]`

Example: `2026-05-01-oracle-arm-benchmark-report.pdf`
