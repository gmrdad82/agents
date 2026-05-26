---
name: ai
description: LLM integration, embeddings, RAG, provider selection, prompt caching, streaming, tool use, safety.
triggers:
  [
    "anthropic / openai / deepseek / voyage / cohere in dependencies",
    "app/ai/ or lib/ai/ exists",
    "pgvector / qdrant / pinecone in use",
  ]
---

# AI

## Project context

Read `docs/EXTRA.md` first. It declares the project's provider(s)
(Anthropic, OpenAI, DeepSeek, local Ollama, ...), default models per
task class (chat, embedding, vision, code), the vector store
(pgvector, Qdrant, Pinecone, Weaviate), the prompt-cache strategy,
the safety / abuse review pass, and any provider-specific quotas /
budgets to respect. Anything declared there overrides the defaults
below.

## Conventions

### Provider selection

- Pick by task class, not by brand loyalty:
  - **Long-context reasoning** — Claude (Opus / Sonnet) and Gemini
    win at 200k+ context. GPT-4 class for general reasoning.
  - **Cheap classification / extraction** — Haiku / GPT-4o-mini /
    DeepSeek-V3-flash. Often 10–50× cheaper for the same accuracy
    at low context.
  - **Embeddings** — Voyage AI (`voyage-3-large`, `voyage-code-2`),
    OpenAI `text-embedding-3-large`, Cohere `embed-v3`. Quality
    differs per domain; benchmark on YOUR data.
  - **Code generation / completion** — Claude Sonnet / Opus,
    GPT-4 class, DeepSeek-Coder.
- Don't lock the architecture to one provider. The integration layer
  should accept any chat-completion / embedding API.

### Prompts

- System prompts are stable; user prompts vary. Cache the system
  prompt aggressively (Anthropic's `cache_control: ephemeral`,
  OpenAI's prompt-caching automatic for ≥1024 tokens, DeepSeek's
  context caching).
- Instructions go in the system prompt. Examples (few-shot) go
  after the system prompt as cached blocks.
- Be specific. "Summarize this" produces variance; "Summarize this
  in 3 bullets, ≤ 20 words each, in the voice of an SRE post-mortem"
  produces reproducible output.
- For structured output: use the provider's structured-output mode
  (`response_format: json_schema` on OpenAI, tool use on Anthropic).
  Don't post-hoc parse free-form JSON.

### Prompt caching

- The cache key is the cumulative prefix. Reorder messages and you
  lose the cache. Keep cached blocks (system, few-shot, document
  context) at the start; put the variable user turn last.
- Cache TTL: 5 minutes (Anthropic ephemeral; renewed on each hit).
  For high-traffic surfaces, the cache effectively stays warm.
- Measure: log `cache_read_input_tokens` and `cache_creation_input_tokens`
  per request. Cache hit ratio > 0.7 on a hot path is the target.
- Reorganize the prompt for cache wins: hoist any stable instruction
  (tool definitions, output schema, context docs) above the user
  message.

### Streaming

- Stream by default for any user-facing latency-sensitive surface.
  First-token latency dominates UX; total time is secondary.
- Handle the stream's `error` event — partial responses still need
  cleanup (close UI spinner, mark message incomplete).
- For tool use during streaming: capture tool_use blocks as they
  finalize, execute, then continue the stream with the result.

### Tool use

- Each tool gets a tight schema. Description tells the model when to
  use it; parameter descriptions tell it what to pass.
- Validate tool inputs server-side. The model will hallucinate
  out-of-range values eventually.
- Return tool results in the format the model expects (often
  `tool_result` blocks). Errors return as `is_error: true` so the
  model can self-correct.
- Tool loops can run away. Cap iterations (10–20 turns), or detect
  repetition and bail.

### Embeddings & RAG

- Chunk size: 200–800 tokens with 10–20% overlap. Tune on your
  retrieval-quality metric, not by intuition.
- Embedding dimension matters for storage cost and recall speed.
  Voyage 3 (1024d), OpenAI v3 large (3072d), Cohere v3 (1024d).
  pgvector / Qdrant index by dimension.
- Normalize vectors if your distance metric assumes it (cosine
  similarity ↔ L2 on normalized vectors).
- Hybrid retrieval (BM25 + vector) beats either alone on most
  corpora. Rerank with a cross-encoder for the top-N.
- Cache embeddings — they're deterministic per (model, input). Don't
  re-embed the same chunk on every query.

### Safety & cost

- Set per-request token caps and timeouts. A runaway prompt with no
  `max_tokens` can produce 100KB of output.
- Per-user rate limits, not just global. One abusive user can burn
  the day's budget.
- Log prompts + completions for review (and abuse-response capability),
  but redact PII at log time, not retroactively.
- Have an off-switch: a feature flag that disables AI calls and
  falls back to a non-AI path. Models go down; provider APIs have
  incidents.

## Anti-patterns

- Don't paste secrets / customer data into your prompts during dev
  without checking the provider's data-retention policy.
- Don't trust the model's confidence. It will lie smoothly.
  Verify load-bearing facts (URLs, function names, library APIs).
- Don't fine-tune before you've tried prompting hard. Fine-tuning
  is expensive to maintain across model upgrades.
- Don't pick a model based on a benchmark from six months ago. The
  pricing and quality landscape moves fast — re-evaluate quarterly.
- Don't embed once and forget. When you switch embedding models, you
  must re-embed the corpus. Plan for it.

## Commands / verification

- For caching: log `usage.cache_creation_input_tokens` /
  `usage.cache_read_input_tokens` (Anthropic) or
  `usage.prompt_tokens_details.cached_tokens` (OpenAI). Track the
  ratio over a week.
- For RAG: measure retrieval recall @ k on a held-out evaluation set
  before tuning generation. If retrieval is bad, generation can't
  save you.
- For tool use: log every tool call + result + final assistant
  message. Failure modes (wrong tool, wrong args, infinite loop) are
  invisible without this trace.
- For cost: pull provider usage exports; alert on a daily budget.
  Surprises arrive on the 1st of the month.
