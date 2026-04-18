import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { createHash } from "crypto";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import pg from "pg";
import { writeFile, mkdir } from "node:fs/promises";
import { join, dirname, resolve } from "node:path";

const { Pool } = pg;

// ---------------------------------------------------------------------------
// Access-level enforcement
// ---------------------------------------------------------------------------

const ACCESS_LEVELS: Record<string, number> = {
  public: 0,
  private: 1,
  secret: 2,
  hidden: 3,
};

function accessLevel(access: string): number {
  return ACCESS_LEVELS[access.toLowerCase()] ?? 1;
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

const DATABASE_URL = process.env.LEDGER_DATABASE_URL;

if (!DATABASE_URL) {
  console.error(
    "LEDGER_DATABASE_URL is not set. The server will start but all queries will fail."
  );
}

let pool: pg.Pool | null = null;

if (DATABASE_URL) {
  pool = new Pool({
    connectionString: DATABASE_URL,
    max: 5,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 5_000,
  });
  pool.on("error", (err) => {
    console.error("Unexpected Postgres pool error:", err.message);
  });
}

async function safeQuery(
  text: string,
  params: unknown[] = []
): Promise<{ rows: Record<string, unknown>[]; error?: string }> {
  if (!pool) {
    return { rows: [], error: "LEDGER_DATABASE_URL not set — Postgres unavailable" };
  }
  try {
    const result = await pool.query(text, params);
    return { rows: result.rows as Record<string, unknown>[] };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Query error:", message);
    return { rows: [], error: message };
  }
}

// ---------------------------------------------------------------------------
// Vault path helper (for create_inbox_note)
// ---------------------------------------------------------------------------

const VAULT_ROOT =
  process.env.LEDGER_VAULT_ROOT ??
  join(dirname(new URL(import.meta.url).pathname), "..", "..", "..");

// ---------------------------------------------------------------------------
// Tool definitions
// ---------------------------------------------------------------------------

const TOOLS = [
  {
    name: "query_notes",
    description:
      "Query notes from the Monty-Ledger vault with optional filters on type, tags, access level, confidence, and role mode.",
    inputSchema: {
      type: "object" as const,
      properties: {
        type: {
          type: "string",
          description: "Filter by note type (e.g. profile, decision, pod).",
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Filter by tags — notes must contain ALL specified tags.",
        },
        access_max: {
          type: "string",
          description:
            'Maximum access level to return. One of: public, private, secret, hidden. Default: "private".',
          default: "private",
        },
        confidence_min: {
          type: "number",
          description:
            "Minimum confidence score (1-5). Only notes with confidence >= this value are returned.",
        },
        role_mode: {
          type: "string",
          description: "Filter by role_mode field.",
        },
        limit: {
          type: "number",
          description: "Max number of results. Default: 20.",
          default: 20,
        },
      },
      additionalProperties: false,
    },
  },
  {
    name: "get_note",
    description:
      "Return the full content and frontmatter for a single note by its vault path.",
    inputSchema: {
      type: "object" as const,
      properties: {
        path: {
          type: "string",
          description: "The vault-relative path of the note.",
        },
      },
      required: ["path"],
      additionalProperties: false,
    },
  },
  {
    name: "search_content",
    description:
      "Full-text search across note content using PostgreSQL pg_trgm similarity.",
    inputSchema: {
      type: "object" as const,
      properties: {
        query: {
          type: "string",
          description: "The search query string.",
        },
        access_max: {
          type: "string",
          description: 'Maximum access level. Default: "private".',
          default: "private",
        },
        limit: {
          type: "number",
          description: "Max results. Default: 10.",
          default: 10,
        },
      },
      required: ["query"],
      additionalProperties: false,
    },
  },
  {
    name: "build_packet",
    description:
      "Build a context packet for a question. Optionally scoped to a pod, which pre-loads its default profiles and searches for relevant evidence. Returns a truncated text block.",
    inputSchema: {
      type: "object" as const,
      properties: {
        question: {
          type: "string",
          description: "The question or topic to build context for.",
        },
        pod_name: {
          type: "string",
          description:
            "Optional pod name. If given, loads the pod's default-load list first.",
        },
        token_budget: {
          type: "number",
          description:
            "Approximate token budget for the packet. Default: 8000.",
          default: 8000,
        },
      },
      required: ["question"],
      additionalProperties: false,
    },
  },
  {
    name: "get_pod",
    description: "Return the full pod definition note by name.",
    inputSchema: {
      type: "object" as const,
      properties: {
        name: {
          type: "string",
          description: "The pod name (matches the title or path slug).",
        },
      },
      required: ["name"],
      additionalProperties: false,
    },
  },
  {
    name: "list_profiles",
    description:
      'List all profile notes in the vault (type="profile", access <= "private").',
    inputSchema: {
      type: "object" as const,
      properties: {},
      additionalProperties: false,
    },
  },
  {
    name: "create_inbox_note",
    description:
      "Create a new AI-proposed note in the vault's 00_Inbox/ directory. Writes both a markdown file and inserts into Postgres.",
    inputSchema: {
      type: "object" as const,
      properties: {
        title: {
          type: "string",
          description: "Note title.",
        },
        content: {
          type: "string",
          description: "Markdown body content (without frontmatter).",
        },
        type: {
          type: "string",
          description: "Note type (e.g. note, decision, profile).",
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Tags for the note.",
        },
      },
      required: ["title", "content", "type", "tags"],
      additionalProperties: false,
    },
  },
];

// ---------------------------------------------------------------------------
// Tool handlers
// ---------------------------------------------------------------------------

async function handleQueryNotes(params: Record<string, unknown>) {
  const type = params.type as string | undefined;
  const tags = params.tags as string[] | undefined;
  const accessMax = (params.access_max as string) ?? "private";
  const confidenceMin = params.confidence_min as number | undefined;
  const roleMode = params.role_mode as string | undefined;
  const limit = Math.min((params.limit as number) ?? 20, 200);

  const maxLevel = accessLevel(accessMax);

  const conditions: string[] = [];
  const values: unknown[] = [];
  let paramIdx = 1;

  // Access ceiling — always enforced
  // We store access as text, so we map in SQL
  conditions.push(
    `CASE LOWER(access) WHEN 'public' THEN 0 WHEN 'private' THEN 1 WHEN 'secret' THEN 2 WHEN 'hidden' THEN 3 ELSE 1 END <= $${paramIdx}`
  );
  values.push(maxLevel);
  paramIdx++;

  if (type) {
    conditions.push(`type = $${paramIdx}`);
    values.push(type);
    paramIdx++;
  }

  if (tags && tags.length > 0) {
    conditions.push(`(SELECT count(DISTINCT t2.tag) FROM tags t2 WHERE t2.note_id = notes.id AND t2.tag = ANY($${paramIdx})) = $${paramIdx + 1}`);
    values.push(tags);
    paramIdx++;
    values.push(tags.length);
    paramIdx++;
  }

  if (confidenceMin !== undefined) {
    conditions.push(`confidence >= $${paramIdx}`);
    values.push(confidenceMin);
    paramIdx++;
  }

  if (roleMode) {
    conditions.push(`role_mode = $${paramIdx}`);
    values.push(roleMode);
    paramIdx++;
  }

  const whereClause =
    conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

  const sql = `
    SELECT path, title, type, (SELECT COALESCE(array_agg(t.tag), ARRAY[]::text[]) FROM tags t WHERE t.note_id = notes.id) AS tags, access, confidence, role_mode, truth_layer, status, created_at
    FROM notes
    ${whereClause}
    ORDER BY created_at DESC
    LIMIT $${paramIdx}
  `;
  values.push(limit);

  const result = await safeQuery(sql, values);
  if (result.error) {
    return { content: [{ type: "text", text: `Error: ${result.error}` }], isError: true };
  }
  return {
    content: [{ type: "text", text: JSON.stringify(result.rows, null, 2) }],
  };
}

async function handleGetNote(params: Record<string, unknown>) {
  const path = params.path as string;
  const accessMax = (params.access_max as string) ?? "private";
  const maxLevel = accessLevel(accessMax);

  const result = await safeQuery(
    `SELECT path, title, type, (SELECT COALESCE(array_agg(t.tag), ARRAY[]::text[]) FROM tags t WHERE t.note_id = notes.id) AS tags, access, confidence, role_mode, truth_layer, status, content, created_at FROM notes WHERE path = $1 AND CASE LOWER(access) WHEN 'public' THEN 0 WHEN 'private' THEN 1 WHEN 'secret' THEN 2 WHEN 'hidden' THEN 3 ELSE 1 END <= $2`,
    [path, maxLevel]
  );

  if (result.error) {
    return { content: [{ type: "text", text: `Error: ${result.error}` }], isError: true };
  }
  if (result.rows.length === 0) {
    return {
      content: [{ type: "text", text: `Note not found: ${path}` }],
      isError: true,
    };
  }

  const note = result.rows[0];
  const frontmatter = Object.fromEntries(
    Object.entries(note).filter(([k]) => k !== "content")
  );

  const output = `---\n${Object.entries(frontmatter)
    .map(([k, v]) => `${k}: ${JSON.stringify(v)}`)
    .join("\n")}\n---\n\n${note.content ?? ""}`;

  return { content: [{ type: "text", text: output }] };
}

async function handleSearchContent(params: Record<string, unknown>) {
  const query = params.query as string;
  const accessMax = (params.access_max as string) ?? "private";
  const limit = Math.min((params.limit as number) ?? 10, 100);
  const maxLevel = accessLevel(accessMax);

  const sql = `
    SELECT path, title, type, (SELECT COALESCE(array_agg(t.tag), ARRAY[]::text[]) FROM tags t WHERE t.note_id = notes.id) AS tags, access, confidence,
           similarity(content, $1) AS sim,
           substring(content FROM 1 FOR 500) AS excerpt
    FROM notes
    WHERE similarity(content, $1) > 0.05
      AND CASE LOWER(access) WHEN 'public' THEN 0 WHEN 'private' THEN 1 WHEN 'secret' THEN 2 WHEN 'hidden' THEN 3 ELSE 1 END <= $2
    ORDER BY sim DESC
    LIMIT $3
  `;

  const result = await safeQuery(sql, [query, maxLevel, limit]);
  if (result.error) {
    return { content: [{ type: "text", text: `Error: ${result.error}` }], isError: true };
  }
  return {
    content: [{ type: "text", text: JSON.stringify(result.rows, null, 2) }],
  };
}

async function handleBuildPacket(params: Record<string, unknown>) {
  const question = params.question as string;
  const podName = params.pod_name as string | undefined;
  const tokenBudget = (params.token_budget as number) ?? 8000;
  const charBudget = tokenBudget * 4;

  const sections: string[] = [];
  sections.push(`# Context Packet\n\n**Question:** ${question}\n`);

  // If a pod is specified, load its definition and default profiles
  if (podName) {
    const podResult = await safeQuery(
      `SELECT path, title, content, tags FROM notes
       WHERE (type = 'pod' OR path LIKE '13_Pods/%') AND (LOWER(title) = LOWER($1) OR path ILIKE '%' || $1 || '%')
       LIMIT 1`,
      [podName]
    );

    if (podResult.error) {
      sections.push(`\n## Pod (error)\n${podResult.error}\n`);
    } else if (podResult.rows.length > 0) {
      const pod = podResult.rows[0];
      sections.push(`\n## Pod: ${pod.title}\n${pod.content}\n`);

      // Parse default-load list from pod content
      // Convention: lines starting with "- [[" are links to load
      const contentStr = String(pod.content ?? "");
      const linkPattern = /\[\[([^\]]+)\]\]/g;
      const defaultLoads: string[] = [];
      let match: RegExpExecArray | null;
      while ((match = linkPattern.exec(contentStr)) !== null) {
        defaultLoads.push(match[1]);
      }

      if (defaultLoads.length > 0) {
        const placeholders = defaultLoads
          .map((_, i) => `$${i + 2}`)
          .join(", ");
        const profileResult = await safeQuery(
          `SELECT path, title, content FROM notes
           WHERE (title = ANY($1) OR path = ANY($1))
             AND CASE LOWER(access) WHEN 'public' THEN 0 WHEN 'private' THEN 1 WHEN 'secret' THEN 2 WHEN 'hidden' THEN 3 ELSE 1 END <= 1`,
          [defaultLoads]
        );

        if (!profileResult.error && profileResult.rows.length > 0) {
          sections.push("\n## Loaded Profiles\n");
          for (const profile of profileResult.rows) {
            sections.push(
              `### ${profile.title}\n${String(profile.content ?? "").slice(0, 1000)}\n`
            );
          }
        }
      }
    }
  }

  // Search for relevant evidence
  const evidenceResult = await safeQuery(
    `SELECT path, title, type,
            similarity(content, $1) AS sim,
            substring(content FROM 1 FOR 800) AS excerpt
     FROM notes
     WHERE similarity(content, $1) > 0.05
       AND CASE LOWER(access) WHEN 'public' THEN 0 WHEN 'private' THEN 1 WHEN 'secret' THEN 2 WHEN 'hidden' THEN 3 ELSE 1 END <= 1
     ORDER BY sim DESC
     LIMIT 15`,
    [question]
  );

  if (!evidenceResult.error && evidenceResult.rows.length > 0) {
    sections.push("\n## Relevant Evidence\n");
    for (const row of evidenceResult.rows) {
      sections.push(
        `### ${row.title} (${row.type}, sim=${Number(row.sim).toFixed(3)})\n${row.excerpt}\n`
      );
    }
  }

  // Assemble and truncate to budget
  let packet = sections.join("\n");
  if (packet.length > charBudget) {
    packet = packet.slice(0, charBudget) + "\n\n[...truncated to token budget]";
  }

  return { content: [{ type: "text", text: packet }] };
}

async function handleGetPod(params: Record<string, unknown>) {
  const name = params.name as string;
  const escapedName = name.replace(/%/g, '\\%').replace(/_/g, '\\_');

  const result = await safeQuery(
    `SELECT path, title, type, (SELECT COALESCE(array_agg(t.tag), ARRAY[]::text[]) FROM tags t WHERE t.note_id = notes.id) AS tags, access, content, created_at FROM notes
     WHERE (type = 'pod' OR path LIKE '13_Pods/%') AND (LOWER(title) = LOWER($1) OR path ILIKE '%' || $2 || '%')
       AND CASE LOWER(access) WHEN 'public' THEN 0 WHEN 'private' THEN 1 WHEN 'secret' THEN 2 WHEN 'hidden' THEN 3 ELSE 1 END <= 1
     LIMIT 1`,
    [name, escapedName]
  );

  if (result.error) {
    return { content: [{ type: "text", text: `Error: ${result.error}` }], isError: true };
  }
  if (result.rows.length === 0) {
    return {
      content: [{ type: "text", text: `Pod not found: ${name}` }],
      isError: true,
    };
  }

  const pod = result.rows[0];
  const output = `---\n${Object.entries(pod)
    .filter(([k]) => k !== "content")
    .map(([k, v]) => `${k}: ${JSON.stringify(v)}`)
    .join("\n")}\n---\n\n${pod.content ?? ""}`;

  return { content: [{ type: "text", text: output }] };
}

async function handleListProfiles(_params: Record<string, unknown>) {
  const result = await safeQuery(
    `SELECT path, title, (SELECT COALESCE(array_agg(t.tag), ARRAY[]::text[]) FROM tags t WHERE t.note_id = notes.id) AS tags, confidence, role_mode, truth_layer, status, created_at
     FROM notes
     WHERE type = 'profile'
       AND CASE LOWER(access) WHEN 'public' THEN 0 WHEN 'private' THEN 1 WHEN 'secret' THEN 2 WHEN 'hidden' THEN 3 ELSE 1 END <= 1
     ORDER BY title`
  );

  if (result.error) {
    return { content: [{ type: "text", text: `Error: ${result.error}` }], isError: true };
  }
  return {
    content: [{ type: "text", text: JSON.stringify(result.rows, null, 2) }],
  };
}

async function handleCreateInboxNote(params: Record<string, unknown>) {
  const title = params.title as string;
  const content = params.content as string;
  const type = params.type as string;
  const tags = params.tags as string[];

  const MAX_CONTENT_SIZE = 100_000;
  if (content.length > MAX_CONTENT_SIZE) {
    return {
      content: [{ type: "text", text: `Rejected: content exceeds ${MAX_CONTENT_SIZE} chars` }],
      isError: true,
    };
  }

  const today = new Date().toISOString().slice(0, 10);
  const slug = title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
  const suffix = Math.random().toString(16).slice(2, 6);
  const filename = `${today}_${slug}-${suffix}.md`;
  const vaultPath = `00_Inbox/${filename}`;

  const safeTitle = title.replace(/"/g, '\\"').replace(/\n/g, ' ');
  const safeTags = tags.map(t => t.replace(/"/g, '').replace(/[\[\]\n]/g, ''));

  const frontmatter = [
    "---",
    `title: "${safeTitle}"`,
    `type: ${type}`,
    `origin_type: ai-proposed`,
    `confidence: 2`,
    `status: review`,
    `access: private`,
    `truth_layer: working`,
    `created: ${today}`,
    `tags: [${safeTags.map((t) => `"${t}"`).join(", ")}]`,
    "---",
  ].join("\n");

  const fullContent = `${frontmatter}\n\n${content}\n`;

  // Write the markdown file to the vault (with path traversal guard)
  const filePath = resolve(join(VAULT_ROOT, vaultPath));
  const resolvedRoot = resolve(VAULT_ROOT);
  if (!filePath.startsWith(resolvedRoot)) {
    return {
      content: [{ type: "text", text: "Rejected: path escapes vault root" }],
      isError: true,
    };
  }
  try {
    await mkdir(dirname(filePath), { recursive: true });
    await writeFile(filePath, fullContent, "utf-8");
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return {
      content: [
        { type: "text", text: `Error writing file: ${message}` },
      ],
      isError: true,
    };
  }

  // Insert into Postgres
  const insertResult = await safeQuery(
    `INSERT INTO notes (id, path, title, type, access, confidence, status, truth_layer, content, content_hash, created_at, origin_type)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
     ON CONFLICT (path) DO UPDATE SET content = EXCLUDED.content, title = EXCLUDED.title
     RETURNING path`,
    [vaultPath, vaultPath, title, type, 'private', 2, 'review', 'working', content, createHash('sha256').update(content).digest('hex').slice(0,16), today, 'ai-proposed']
  );

  if (insertResult.error) {
    return {
      content: [
        {
          type: "text",
          text: `File written but not indexed. Run /sync to fix. (${insertResult.error})`,
        },
      ],
      isError: true,
    };
  }

  // Insert tags into the tags table
  if (tags.length > 0) {
    const tagValues = tags.map((_, i) => `($1, $${i + 2})`).join(", ");
    const tagParams = [vaultPath, ...tags];
    await safeQuery(
      `INSERT INTO tags (note_id, tag) VALUES ${tagValues} ON CONFLICT DO NOTHING`,
      tagParams
    );
  }

  return {
    content: [
      {
        type: "text",
        text: `Created inbox note: ${vaultPath}\nFile written and inserted into database.`,
      },
    ],
  };
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

type ToolHandler = (params: Record<string, unknown>) => Promise<{
  content: { type: string; text: string }[];
  isError?: boolean;
}>;

const HANDLERS: Record<string, ToolHandler> = {
  query_notes: handleQueryNotes,
  get_note: handleGetNote,
  search_content: handleSearchContent,
  build_packet: handleBuildPacket,
  get_pod: handleGetPod,
  list_profiles: handleListProfiles,
  create_inbox_note: handleCreateInboxNote,
};

// ---------------------------------------------------------------------------
// MCP Server
// ---------------------------------------------------------------------------

const server = new Server(
  {
    name: "monty-ledger",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: TOOLS };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const handler = HANDLERS[name];

  if (!handler) {
    return {
      content: [{ type: "text", text: `Unknown tool: ${name}` }],
      isError: true,
    };
  }

  try {
    return await handler((args ?? {}) as Record<string, unknown>);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`Tool ${name} error:`, message);
    return {
      content: [{ type: "text", text: `Internal error: ${message}` }],
      isError: true,
    };
  }
});

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Monty-Ledger MCP server running on stdio");
}

main().catch((err) => {
  console.error("Fatal error starting server:", err);
  process.exit(1);
});
