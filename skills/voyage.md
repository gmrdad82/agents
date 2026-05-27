---
name: voyage
description: Voyage AI embeddings — model selection, chunking, dimensions, reranking, integration.
triggers:
  [
    "voyageai / voyage in dependencies",
    "VOYAGE_API_KEY env var",
    "pgvector with 1024 / 1536 / 2048 dim columns",
  ]
---

# Voyage

## Project context

Read `docs/EXTRA.md` first. It declares which Voyage models the
project uses (general, code, finance, multilingual), the storage
backend (pgvector, Qdrant, Pinecone), the chunking strategy, and
the rate-limit / cost guardrails. Anything declared there overrides
the defaults below.

## Conventions

### Model selection

- `voyage-3-large` — best general-purpose retrieval. 1024d. Use for
  most knowledge-base / RAG workloads.
- `voyage-3` — cheaper, ~85–90% the quality. Use for high-volume,
  cost-sensitive embedding (logs, comments, low-stakes search).
- `voyage-code-2` — code search and code-QA. Trained on source.
  Don't use general models for code-heavy corpora.
- `voyage-finance-2`, `voyage-law-2`, `voyage-multilingual-2` —
  domain-specific. Try them only if the general models underperform
  on your eval set; the domain models are not always better.
- `rerank-2` (and `rerank-2-lite`) — cross-encoder rerank for the
  top-N retrieved chunks. Often the single biggest quality win after
  retrieval is in place.

### Embedding requests

- Batch up to 128 texts per request (check current API limit).
  Single-text requests waste round-trips.
- `input_type`: `document` when embedding the corpus; `query` when
  embedding the user's question. The two encoders are slightly
  asymmetric for retrieval quality.
- `truncation: true` for inputs you can't pre-trim. Voyage
  truncates rather than rejects oversized inputs.
- Use the latest model, but pin the version (`voyage-3-large`, not
  `voyage-3-large-latest`). Re-embedding the corpus on a model
  upgrade is the cost of the upgrade.

### Chunking

- 300–500 tokens per chunk with 10% overlap is a reasonable default.
  Tune on YOUR eval set; the right number is corpus-dependent.
- Respect semantic boundaries (paragraph, heading, function) over
  fixed token windows when feasible. A chunk that splits a sentence
  embeds poorly.
- Attach metadata (source, title, section, author, timestamp) to
  every chunk. Filters at retrieval are usually more useful than
  more embeddings.

### Reranking

- Retrieve top 20–50 with vector search → rerank to top 5–10 with
  `rerank-2`. The latency cost is small; the recall gain at low k
  is usually large.
- Reranking handles "lexical match in question, not in corpus" cases
  that pure embeddings miss.

### Storage

- pgvector: `vector(1024)` column for `voyage-3-large` / `voyage-3`,
  `vector(1536)` for `voyage-code-2`. Index with HNSW (`m=16,
ef_construction=64`) for most workloads; tune `ef_search` on the
  query side per recall/latency target.
- For Qdrant / Pinecone: cosine distance with normalized vectors
  (Voyage outputs are normalized — confirm in the API response if
  building from raw).

## Anti-patterns

- Don't re-embed the entire corpus on every minor change. Hash the
  chunk + `(model, version)` and re-embed only when the hash
  changes.
- Don't pass raw HTML / markdown noise to the embedder. Strip
  navigation, code fences (unless using `voyage-code-2`), and
  boilerplate first.
- Don't compare scores across models. Voyage `voyage-3-large` cosine
  scores aren't directly comparable to OpenAI `text-embedding-3`
  scores; absolute thresholds need re-calibration per model.
- Don't rerank without first measuring retrieval recall. If your
  top-50 doesn't contain the right chunk, reranking won't conjure it.

## Commands / verification

- Embed a known query against your corpus; eyeball the top results.
  Garbage retrieval is usually obvious without metrics.
- Measure **recall @ k** on an eval set (held-out question →
  expected chunk). Track it across chunking / model changes.
- Watch token usage in the Voyage dashboard. Daily spike → either
  unexpected re-embedding or a broken cache.
- For rerank: A/B retrieval-only vs retrieval+rerank on the eval
  set. If rerank doesn't improve @ 5, don't pay for it.
- `curl -H "Authorization: Bearer $VOYAGE_API_KEY"
https://api.voyageai.com/v1/embeddings -d '{"model":"voyage-3-large",
"input":["hello"]}'` — confirm API reachability and key validity.
