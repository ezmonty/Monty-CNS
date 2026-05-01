# Airlock Doctrine — Annotated Bibliography (CNS Mirror)

**Canonical source:** `valor2.0/docs/m2codex/AIRLOCK_BIBLIOGRAPHY.md`
This is the condensed CNS-side mirror for the brain vault and RAG retrieval.
Full annotations live in the valor2.0 repo.

*This document is an **annotated bibliography** — a works-cited page where
each source carries a brief note on what it contributes to the doctrine.
Sometimes called a "fold-out" or "reference index" in living design documents.*

---

## What Each Category Addresses

| Category | Doctrine Layer |
|---|---|
| Prompt injection / LLM-agent security | Threat model, Layers 1–2 (quarantine, P-LLM/Q-LLM) |
| Capability / access-control foundations | Layers 3, 7 (PDP, capability tokens, agent identity) |
| Standards | All layers — compliance anchoring |
| Zero trust / workload identity | Layers 0, 7 (external enforcement, per-agent SVID) |
| Tamper-evident logging | Layer 6 (hash-chained audit, HSM signing) |
| Fraud / financial controls | Layer 4 (behavioral velocity governor) |
| AI safety / human-in-the-loop | Layer 8 (OOB confirmation, corrigibility) |

---

## Prompt Injection and LLM-Agent Security

- **Greshake et al. (AISec '23)** — Foundational empirical paper on indirect
  prompt injection in deployed applications. Establishes the attack class.
  Dataset used in P2 adversarial CI testing.

- **Perez & Ribeiro (2022, arXiv:2211.09527)** — Taxonomy of injection
  techniques. Proves delimiter-based separation is insufficient; structural
  separation (quarantine) is required.

- **Willison (2023, simonwillison.net)** — Original Dual-LLM pattern: one LLM
  has tools but never sees untrusted content; one LLM sees untrusted content
  but has no tools. Ancestor of Layer 2 (P-LLM / Q-LLM).

- **Debenedetti et al. / Google DeepMind (2025, arXiv:2503.18813) — CaMeL** —
  Formalizes the Dual-LLM into typed `Plan` objects with value sources and taint
  propagation. Layers 1, 2, and 3 of the Valor airlock implement this pattern.

- **Debenedetti et al. (2024, arXiv:2406.13352) — AgentDojo** — Benchmark for
  evaluating attacks and defenses on LLM agents. P2 adversarial CI target.

- **Anthropic — Mitigating jailbreaks and prompt injections** — Guidance on
  framing untrusted content as data in system prompts. Informs the
  `<untrusted source="..." sha256="...">` serialization in `core/llm_router.py`.

- **OWASP LLM Top 10 v2025 — LLM01, LLM02, LLM05, LLM06** — Industry
  classification. LLM01 (prompt injection) = primary threat. LLM06 (excessive
  agency) = motivates PDP least-authority design.

---

## Capability and Access-Control Foundations

- **Dennis & Van Horn (1966, CACM)** — Original capability model: unforgeable
  token grants specific access to a specific object. Direct ancestor of
  `core/capability.py` argument-hash-bound tokens.

- **Lampson (1974, ACM OS Review)** — Access matrix + complete mediation:
  every access checked every time. Basis for deny-first PDP.

- **Saltzer & Schroeder (1975, Proc. IEEE)** — Eight design principles. Three
  load-bearing: least common mechanism, fail-safe defaults, complete mediation.

- **Hardy (1988, ACM OS Review) — "The Confused Deputy"** — Named and
  formalized the attack: a program with legitimate authority is tricked into
  acting for an attacker. Prompt injection is this attack realized in LLMs.
  Capability tokens (Layer 3) are the structural mitigation.

- **Miller (2006, PhD thesis, Johns Hopkins)** — Object-capability discipline:
  authority propagates only through explicit token transfer, never ambient.
  CaMeL value-source tagging and argument-hash binding implement this.

- **Yee (2004, IEEE S&P)** — Capability systems must be usable to be followed.
  Informs the OOB UX design (Layer 8): friction proportional to risk.

- **Lampson, Abadi, Burrows, Wobber (1992, ACM TOCS)** — "Speaks for"
  delegation in distributed systems. PDP mints capabilities "on behalf of"
  the principal for agents.

- **Provos (2003, USENIX) — systrace** — Predecessor to seccomp / syscall
  filtering. ShellAgent allowlist follows same allow-by-explicit-schema model.

---

## Standards

- **NIST SP 800-53 Rev. 5** — AC-3 (access enforcement → PDP), AC-4 (info
  flow → taint/egress), AC-6 (least privilege → per-agent SVID), AU-6 (audit
  review → Layer 6), SC-7 (boundary protection → egress controls).

- **NIST SP 800-207** — Zero Trust Architecture. Motivates removing
  `ALLOW_INSECURE_LOCAL` and out-of-process PDP (Decision 5).

- **NIST SP 800-63B** — AAL1/2/3. Layer 8 OOB targets AAL3: hardware-attested,
  phishing-resistant, verifier-impersonation-resistant.

- **NIST SP 800-92** — Log management: tamper protection, external sinks.
  Informs WORM sink (Layer 0) and hash-chain extension (Layer 6).

- **PCI DSS v4.0** — §6 (secure systems), §10 (log/monitor). Velocity controls
  and issuer-side card caps satisfy payment-adjacent workloads.

- **W3C PROV-DM (2013)** — Provenance data model. Audit DAG in Layer 6
  (plan_id → capability_id → action → evidence) is PROV-DM compatible.

- **FIDO2 / WebAuthn Level 2** — Hardware-attestation standard for OOB
  confirmation (Layer 8, Decision 2). Key never leaves Secure Enclave.

- **ISO 8583** — Card-network velocity semantics. Issuer-side limits (Layer 0,
  Ramp) enforce these before any Valor code runs.

- **RFC 7519 JWT / RFC 8392 CWT** — Token format standards for per-agent
  JWT-SVIDs (Decision 3, step-ca).

---

## Zero Trust, Workload Identity, Immutable Infrastructure

- **Ward & Beyer / Google (2014, BeyondCorp)** — Zero Trust at network level:
  device + user identity, not location. Basis for removing localhost bypass.

- **Burkhardt et al. / Google (2019, BeyondProd)** — ZT for service-to-service:
  every RPC authenticated by workload identity. PDP container + SVID model.

- **SPIFFE / SPIRE (CNCF)** — Open workload identity standard. Decision 3
  chose step-ca for P1; SPIRE is P2 upgrade target.

- **Linux IMA / EVM** — Boot-time code integrity measurement. SHA-256 manifest
  attestation at agent startup (Layer 0) follows this model.

- **Sigstore** — Keyless code signing toolchain. Alternative to offline signing
  key for code-integrity manifest.

---

## Tamper-Evident Logging

- **Haber & Stornetta (1991, J. Cryptology)** — Original hash-chaining: each
  record includes hash of the previous. Valor `incident_audit_store.py` H4.

- **Schneier & Kelsey (1998, USENIX)** — Secure logs on untrusted machines:
  forward-integrity via key derivation + external verification. Motivates HSM
  signing (H5) and WORM mirror.

- **Crosby & Wallach (2009, USENIX)** — Merkle-tree append-only logs with
  efficient membership proofs. Audit DAG follows Merkle-DAG structure.

---

## Fraud and Financial Controls

- **Bolton & Hand (2002, Statistical Science)** — Statistical fraud detection
  survey. Behavioral velocity governor (Layer 4) implements rule-based anomaly
  detection: velocity windows, first-time-recipient, off-hours, taint-spike.

- **FFIEC Retail Payment Systems Handbook** — Federal examination standard:
  payment-adjacent systems must log, monitor, and anomaly-detect behavioral
  patterns.

- **Denning (1987, IEEE TSE) — Intrusion Detection Model** — Statistical
  profile of normal behavior, alert on deviations. Per-agent velocity windows
  are the "audit records" in Denning's formalization.

---

## AI Safety and Human-in-the-Loop

- **Amodei et al. (2016, arXiv:1606.06565) — Concrete Problems in AI Safety**
  — Safe interruptibility, avoiding side effects. OOB confirmation (Layer 8)
  and Draft-first doctrine address the "limited off-switch" problem.

- **Russell (2019, Viking) — Human Compatible** — Provably beneficial AI via
  corrigibility: systems defer to human correction. Layer 8 OOB + Draft-first
  are engineering implementations of corrigibility.

- **Christiano et al. (2017, NeurIPS) — RLHF** — Human preference signals as
  a live execution signal, not just training. Layer 8 keeps humans in the
  approval loop at execution time.

- **Bonneau et al. (2012, IEEE S&P) — The Quest to Replace Passwords** —
  Evaluated authentication schemes on 25 properties. FIDO2/WebAuthn scores
  highest on security + deployability. Informs Decision 2 (OOB transport).

---

## How This Document Is Used in CNS

- **RAG namespace:** `doctrine.security` — retrieved alongside
  `airlock-doctrine.md` and `actor-model.md` when agents query security topics.
- **Cross-repo:** canonical full annotations are in
  `valor2.0/docs/m2codex/AIRLOCK_BIBLIOGRAPHY.md`.
- **Index:** `docs/security/README.md` lists this under the security doc index.
